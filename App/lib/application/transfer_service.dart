// lib/application/transfer_service.dart
// Ultra High-Performance Adaptive LAN / P2P File Transfer Service.
// Automatically detects Wi-Fi bands (6GHz / 5GHz / 2.4GHz), link speeds,
// negotiates optimal streaming parameters, dynamically tunes chunk sizes (1MB -> 16MB),
// and benchmarks throughput continuously in real-time.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../core/audio/sound_effect_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/adaptive_throughput_tuner.dart';
import '../core/network/capability_negotiator.dart';
import '../core/network/wifi_capability_service.dart';
import '../core/utils/file_utils.dart';
import '../data/local/daos/activity_dao.dart';
import '../data/local/daos/transfer_dao.dart';
import '../data/local/database.dart';
import '../data/transport/protocol.dart';
import '../data/transport/tcp_client.dart';
import '../domain/entities/transfer.dart';
import 'settings_service.dart';
import 'web_portal_server.dart';

class _ActiveIncomingTransfer {
  _ActiveIncomingTransfer({
    required this.transferId,
    required this.filename,
    required this.mimeType,
    required this.totalBytes,
    required this.sha256Expected,
    required this.senderDeviceId,
    required this.senderDeviceName,
    required this.tempFile,
    required this.sink,
    required this.startedAt,
    required this.tuner,
  });

  final String transferId;
  final String filename;
  final String mimeType;
  final int totalBytes;
  final String sha256Expected;
  final String senderDeviceId;
  final String senderDeviceName;
  final File tempFile;
  final IOSink sink;
  final DateTime startedAt;
  final AdaptiveThroughputTuner tuner;

  int bytesReceived = 0;
}

class TransferService {
  TransferService({
    required this.settingsService,
    required this.myDeviceId,
    required this.myDeviceName,
    this.transferDao,
    this.activityDao,
  }) {
    _initNotifications();
    if (!kIsWeb) {
      WebPortalServer.instance.transferService = this;
    }
  }

  void emitIncomingTransfer(Transfer transfer) {
    _emit(transfer);
  }

  Future<void> recordCompletedTransfer(Transfer transfer) async {
    await _recordTransfer(transfer);
    _showNotificationComplete(
      id: transfer.transferId.hashCode,
      title: 'Received ${transfer.filename}',
      body: 'Saved to ${transfer.localPath?.split(Platform.pathSeparator).last ?? 'Downloads'}',
    );
  }

  final SettingsService settingsService;
  final String myDeviceId;
  final String myDeviceName;
  final TransferDao? transferDao;
  final ActivityDao? activityDao;

  final _transfers = <String, Transfer>{};
  final _progressController = StreamController<Transfer>.broadcast();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final Map<String, _ActiveIncomingTransfer> _incomingSessions = {};

  Stream<Transfer> get transferUpdates => _progressController.stream;
  List<Transfer> get activeTransfers =>
      _transfers.values.where((t) => t.isActive).toList();

  bool _notificationsReady = false;

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const settings = InitializationSettings(android: android, iOS: ios, linux: linux);
    try {
      final res = await _notifications.initialize(settings);
      _notificationsReady = res ?? true;

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              'ecosystem_transfers',
              'File Transfers',
              description: 'Notifications for incoming and outgoing file transfers',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              'ecosystem_transfers_progress',
              'Transfer Progress',
              description: 'Ongoing transfer progress notifications',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
              showBadge: false,
            ),
          );
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (e) {
      logger.warning('TransferService', 'Failed to initialize notifications: $e');
      _notificationsReady = true;
    }
  }

  // ── Outgoing File Streaming ──────────────────────────────────────────────────

  Future<void> sendFile({
    required String filePath,
    required PeerConnection connection,
    required String peerDeviceId,
    required String peerDeviceName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final filename = file.path.split(Platform.pathSeparator).last;
    final totalBytes = await file.length();
    final transferId = const Uuid().v4();

    final transfer = Transfer(
      transferId: transferId,
      filename: filename,
      mimeType: _guessMimeType(filename),
      totalBytes: totalBytes,
      direction: TransferDirection.outgoing,
      peerDeviceId: peerDeviceId,
      peerDeviceName: peerDeviceName,
      state: TransferState.preparing,
      startedAt: DateTime.now(),
    );
    _emit(transfer);

    // ── Direct Web Client Mode (iPad, Web Browser) ─────────────────────────
    if (peerDeviceId.startsWith('web-') || peerDeviceId.contains('web')) {
      WebPortalServer.instance.stageFileForWebDownload(
        transferId: transferId,
        filename: filename,
        filePath: file.path,
        totalBytes: totalBytes,
        targetDeviceId: peerDeviceId,
      );
      final completedTransfer = transfer.copyWith(
        state: TransferState.completed,
        completedAt: DateTime.now(),
      );
      _emit(completedTransfer);
      await _recordTransfer(completedTransfer);
      _showNotificationComplete(
        id: transferId.hashCode,
        title: 'Sent $filename to Web Client',
        body: 'File is ready for download on $peerDeviceName',
      );
      logger.info('TransferService', 'Staged $filename ($totalBytes bytes) for Web Client download');
      return;
    }

    // ── Direct Ultra-High-Speed Binary Stream (HTTP/2 LAN Mode) ──────────────
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final targetPort = connection.port == 8080 ? 8080 : 8080;
      final req = await client.post(connection.address, targetPort, '/api/transfer_stream');
      req.headers.set('X-Transfer-Id', transferId);
      req.headers.set('X-Filename', Uri.encodeComponent(filename));
      req.headers.set('X-Total-Bytes', totalBytes.toString());
      req.headers.set('X-Sender-Device-Id', myDeviceId);
      req.headers.set('X-Sender-Device-Name', Uri.encodeComponent(myDeviceName));
      req.headers.chunkedTransferEncoding = false;
      req.contentLength = totalBytes;

      final tuner = AdaptiveThroughputTuner(
        totalBytes: totalBytes,
        initialChunkSizeBytes: 1024 * 1024,
        maxChunkSizeBytes: 8 * 1024 * 1024,
      );

      _emit(transfer.copyWith(state: TransferState.transferring));

      int bytesSent = 0;
      final fileStream = file.openRead();
      await for (final chunk in fileStream) {
        req.add(chunk);
        bytesSent += chunk.length;
        tuner.recordProgress(chunk.length);
        final snap = tuner.getSnapshot();
        final eta = snap.speedBytesPerSec > 0
            ? ((totalBytes - bytesSent) / snap.speedBytesPerSec).round()
            : null;

        _emit(transfer.copyWith(
          state: TransferState.transferring,
          progress: TransferProgress(
            bytesTransferred: bytesSent,
            totalBytes: totalBytes,
            speedBytesPerSec: snap.speedBytesPerSec,
            etaSeconds: eta,
          ),
        ));

        _showNotificationProgress(
          id: transferId.hashCode,
          title: 'Sending $filename (${snap.speedMBps.toStringAsFixed(1)} MB/s)',
          progress: (snap.percentage * 100).toInt(),
        );
      }

      final resp = await req.close();
      if (resp.statusCode == 200) {
        final completedTransfer = transfer.copyWith(
          state: TransferState.completed,
          completedAt: DateTime.now(),
        );
        _emit(completedTransfer);
        await _recordTransfer(completedTransfer);
        _showNotificationComplete(
          id: transferId.hashCode,
          title: 'Sent $filename',
          body: 'Transferred to $peerDeviceName',
        );
        logger.info('TransferService', 'Successfully sent $filename ($totalBytes bytes) via Direct Ultra-High Speed Stream');
        return;
      }
    } catch (e) {
      logger.info('TransferService', 'Direct HTTP stream unavailable, using socket fallback: $e');
    }

    // ── Socket Fallback ────────────────────────────────────────────────────────
    final localCap = await WifiCapabilityService.instance.detectCapabilities();
    final sha256Hash = '';

    // 2. Send offer with network capabilities
    final offer = ProtocolMessage(
      version: kProtocolVersion,
      type: msgTransferOffer,
      messageId: const Uuid().v4(),
      sourceDeviceId: myDeviceId,
      timestamp: DateTime.now(),
      payload: {
        'transferId': transferId,
        'filename': filename,
        'mimeType': _guessMimeType(filename),
        'totalBytes': totalBytes,
        'sha256Hash': sha256Hash,
        'capabilities': localCap.toJson(),
      },
    );
    await connection.send(offer);

    // 3. Wait for accept & negotiate
    ProtocolMessage? acceptMsg;
    try {
      acceptMsg = await connection.messages
          .where((m) =>
              m.type == msgTransferAccept &&
              m.payload['transferId'] == transferId)
          .timeout(const Duration(seconds: 15))
          .first;
    } catch (_) {}

    if (acceptMsg == null) {
      _emit(transfer.copyWith(
        state: TransferState.failed,
        errorMessage: 'Transfer was rejected or timed out.',
      ));
      return;
    }

    // 4. Negotiate optimal transfer configuration
    final remoteCapJson = acceptMsg.payload['capabilities'] as Map<String, dynamic>?;
    final remoteCap = remoteCapJson != null
        ? WifiCapability.fromJson(remoteCapJson)
        : WifiCapability.fallback;

    final config = CapabilityNegotiator.negotiate(
      localCap: localCap,
      remoteCap: remoteCap,
      totalFileSizeBytes: totalBytes,
    );

    logger.info('TransferService', 'Streaming with $config');
    _emit(transfer.copyWith(state: TransferState.transferring));

    // 5. Adaptive Throughput Tuner & Streaming I/O
    final tuner = AdaptiveThroughputTuner(
      totalBytes: totalBytes,
      initialChunkSizeBytes: config.initialChunkSizeBytes,
      maxChunkSizeBytes: config.maxChunkSizeBytes,
    );

    final raf = await file.open(mode: FileMode.read);
    int bytesSent = 0;

    try {
      while (bytesSent < totalBytes) {
        final currentChunkSize = min(tuner.currentChunkSize, totalBytes - bytesSent);
        final chunkData = await raf.read(currentChunkSize);
        if (chunkData.isEmpty) break;

        final chunkMsg = ProtocolMessage(
          version: kProtocolVersion,
          type: msgTransferChunk,
          messageId: const Uuid().v4(),
          sourceDeviceId: myDeviceId,
          timestamp: DateTime.now(),
          payload: {
            'transferId': transferId,
            'offset': bytesSent,
            'length': chunkData.length,
            'data': base64Encode(chunkData),
          },
        );

        await connection.send(chunkMsg);
        bytesSent += chunkData.length;
        tuner.recordProgress(chunkData.length);

        final snap = tuner.getSnapshot();
        final eta = snap.speedBytesPerSec > 0
            ? ((totalBytes - bytesSent) / snap.speedBytesPerSec).round()
            : null;

        _emit(transfer.copyWith(
          state: TransferState.transferring,
          progress: TransferProgress(
            bytesTransferred: bytesSent,
            totalBytes: totalBytes,
            speedBytesPerSec: snap.speedBytesPerSec,
            etaSeconds: eta,
          ),
        ));

        _showNotificationProgress(
          id: transferId.hashCode,
          title: 'Sending $filename (${snap.speedMBps.toStringAsFixed(1)} MB/s)',
          progress: (snap.percentage * 100).toInt(),
        );
      }
    } finally {
      await raf.close();
    }

    // 6. Complete handshake
    final complete = ProtocolMessage(
      version: kProtocolVersion,
      type: msgTransferComplete,
      messageId: const Uuid().v4(),
      sourceDeviceId: myDeviceId,
      timestamp: DateTime.now(),
      payload: {
        'transferId': transferId,
        'sha256Hash': sha256Hash,
      },
    );
    await connection.send(complete);

    final completedTransfer = transfer.copyWith(
      state: TransferState.completed,
      completedAt: DateTime.now(),
    );
    _emit(completedTransfer);

    _showNotificationComplete(
      id: transferId.hashCode,
      title: 'Sent $filename',
      body: 'Transferred via ${config.transportMode} to $peerDeviceName',
    );

    await _recordTransfer(completedTransfer);
    logger.info('TransferService', 'Successfully sent $filename ($totalBytes bytes) via ${config.transportMode}');
  }

  // ── Incoming Socket Handler ─────────────────────────────────────────────────

  Future<void> handleIncomingMessage(ProtocolMessage msg, Socket socket) async {
    try {
      if (msg.type == msgTransferOffer) {
        final transferId = msg.payload['transferId'] as String;
        final filename = msg.payload['filename'] as String;
        final mimeType =
            msg.payload['mimeType'] as String? ?? 'application/octet-stream';
        final totalBytes = (msg.payload['totalBytes'] as num).toInt();
        final sha256Hash = msg.payload['sha256Hash'] as String? ?? '';
        final senderDeviceId = msg.sourceDeviceId;
        final senderDeviceName = msg.payload['senderDeviceName'] as String? ?? 'Peer';

        final saveDir = await settingsService.getReceiveFolder();
        await Directory(saveDir).create(recursive: true);
        final tempFile = File(
            '$saveDir${Platform.pathSeparator}.tmp_${transferId}_$filename');
        final sink = tempFile.openWrite();

        final localCap = await WifiCapabilityService.instance.detectCapabilities();

        final tuner = AdaptiveThroughputTuner(
          totalBytes: totalBytes,
          initialChunkSizeBytes: 1024 * 1024,
          maxChunkSizeBytes: 8 * 1024 * 1024,
        );

        _incomingSessions[transferId] = _ActiveIncomingTransfer(
          transferId: transferId,
          filename: filename,
          mimeType: mimeType,
          totalBytes: totalBytes,
          sha256Expected: sha256Hash,
          senderDeviceId: senderDeviceId,
          senderDeviceName: senderDeviceName,
          tempFile: tempFile,
          sink: sink,
          startedAt: DateTime.now(),
          tuner: tuner,
        );

        final transfer = Transfer(
          transferId: transferId,
          filename: filename,
          mimeType: mimeType,
          totalBytes: totalBytes,
          direction: TransferDirection.incoming,
          peerDeviceId: senderDeviceId,
          peerDeviceName: senderDeviceName,
          state: TransferState.transferring,
          startedAt: DateTime.now(),
        );
        _emit(transfer);

        // Send accept with local capabilities
        final accept = ProtocolMessage(
          version: kProtocolVersion,
          type: msgTransferAccept,
          messageId: const Uuid().v4(),
          sourceDeviceId: myDeviceId,
          timestamp: DateTime.now(),
          payload: {
            'transferId': transferId,
            'capabilities': localCap.toJson(),
          },
        );
        socket.write('${accept.encode()}\n');
        await socket.flush();
      } else if (msg.type == msgTransferChunk) {
        final transferId = msg.payload['transferId'] as String;
        final dataBase64 = msg.payload['data'] as String;
        final bytes = base64Decode(dataBase64);

        final session = _incomingSessions[transferId];
        if (session != null) {
          session.sink.add(bytes);
          session.bytesReceived += bytes.length;
          session.tuner.recordProgress(bytes.length);

          final snap = session.tuner.getSnapshot();
          final eta = snap.speedBytesPerSec > 0
              ? ((session.totalBytes - session.bytesReceived) / snap.speedBytesPerSec).round()
              : null;

          final current = _transfers[transferId];
          if (current != null) {
            _emit(current.copyWith(
              state: TransferState.transferring,
              progress: TransferProgress(
                bytesTransferred: session.bytesReceived,
                totalBytes: session.totalBytes,
                speedBytesPerSec: snap.speedBytesPerSec,
                etaSeconds: eta,
              ),
            ));

            _showNotificationProgress(
              id: transferId.hashCode,
              title: 'Receiving ${session.filename} (${snap.speedMBps.toStringAsFixed(1)} MB/s)',
              progress: (snap.percentage * 100).toInt(),
            );
          }
        }
      } else if (msg.type == msgTransferComplete) {
        final transferId = msg.payload['transferId'] as String;
        final session = _incomingSessions.remove(transferId);
        if (session != null) {
          try {
            await session.sink.flush();
            await session.sink.close();
          } catch (_) {}

          final saveDir = await settingsService.getReceiveFolder();
          await Directory(saveDir).create(recursive: true);

          var finalFile = File('$saveDir${Platform.pathSeparator}${session.filename}');
          int counter = 1;
          while (await finalFile.exists()) {
            final dot = session.filename.lastIndexOf('.');
            if (dot != -1) {
              final base = session.filename.substring(0, dot);
              final ext = session.filename.substring(dot);
              finalFile = File('$saveDir${Platform.pathSeparator}$base ($counter)$ext');
            } else {
              finalFile = File('$saveDir${Platform.pathSeparator}${session.filename} ($counter)');
            }
            counter++;
          }

          try {
            await session.tempFile.rename(finalFile.path);
          } catch (_) {
            await session.tempFile.copy(finalFile.path);
            try {
              await session.tempFile.delete();
            } catch (_) {}
          }

          final current = _transfers[transferId];
          if (current != null) {
            final completed = current.copyWith(
              state: TransferState.completed,
              completedAt: DateTime.now(),
              localPath: finalFile.path,
            );
            _emit(completed);
            await _recordTransfer(completed);
          }

          _showNotificationComplete(
            id: transferId.hashCode,
            title: 'Received ${session.filename}',
            body: 'Saved to ${finalFile.path.split(Platform.pathSeparator).last}',
          );

          // Send complete ACK back over socket
          try {
            final ack = ProtocolMessage(
              version: kProtocolVersion,
              type: 'transfer_complete_ack',
              messageId: const Uuid().v4(),
              sourceDeviceId: myDeviceId,
              timestamp: DateTime.now(),
              payload: {'transferId': transferId, 'status': 'success'},
            );
            socket.write('${ack.encode()}\n');
            await socket.flush();
          } catch (_) {}
        }
      }
    } catch (e) {
      logger.warning('TransferService', 'Error handling incoming transfer message: $e');
    }
  }

  void _emit(Transfer transfer) {
    _transfers[transfer.transferId] = transfer;
    if (!_progressController.isClosed) {
      _progressController.add(transfer);
    }
  }

  Future<void> _recordTransfer(Transfer t) async {
    if (transferDao != null) {
      try {
        await transferDao!.insertTransfer(
          TransferTableCompanion(
            transferId: Value(t.transferId),
            filename: Value(t.filename),
            mimeType: Value(t.mimeType),
            totalBytes: Value(t.totalBytes),
            direction: Value(t.direction.name),
            peerDeviceId: Value(t.peerDeviceId),
            peerDeviceName: Value(t.peerDeviceName),
            state: Value(t.state.name),
            startedAt: Value(t.startedAt),
            completedAt: Value(t.completedAt),
            localPath: Value(t.localPath),
            errorMessage: Value(t.errorMessage),
          ),
        );
      } catch (e) {
        logger.warning('TransferService', 'Failed to store transfer in database: $e');
      }
    }

    if (activityDao != null) {
      try {
        await activityDao!.insertActivity(
          ActivityTableCompanion(
            entryId: Value(const Uuid().v4()),
            type: Value(t.direction == TransferDirection.incoming
                ? 'file_received'
                : 'file_sent'),
            peerDeviceName: Value(t.peerDeviceName),
            description: Value('${t.direction == TransferDirection.incoming ? 'Received' : 'Sent'} ${t.filename}'),
            timestamp: Value(DateTime.now()),
          ),
        );
      } catch (e) {
        logger.warning('TransferService', 'Failed to store activity in database: $e');
      }
    }
  }

  int _lastProgressNotifTime = 0;
  int _lastProgressPercent = -1;

  void _showNotificationProgress({required int id, required String title, required int progress}) {
    if (kIsWeb) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle progress notification updates to prevent system rate-limiting
    if (progress != 0 && progress != 100 && (now - _lastProgressNotifTime < 350) && (progress == _lastProgressPercent)) {
      return;
    }
    _lastProgressNotifTime = now;
    _lastProgressPercent = progress;

    final safeId = (id.abs() % 100000);
    final android = AndroidNotificationDetails(
      'ecosystem_transfers_progress',
      'Transfer Progress',
      channelDescription: 'Ongoing transfer progress notifications with progress bar',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );
    try {
      _notifications.show(
        safeId,
        title,
        '$progress% • In Progress',
        NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(presentAlert: false, presentBanner: false),
        ),
      );
    } catch (_) {}
  }

  void _showNotificationComplete({required int id, required String title, required String body, String? localPath}) {
    if (kIsWeb) return;
    final safeId = (id.abs() % 100000);
    // Dismiss ongoing progress notification
    try {
      _notifications.cancel(safeId);
    } catch (_) {}

    if (Platform.isWindows) {
      try {
        final cleanTitle = title.replaceAll('"', '`"').replaceAll("'", "`'");
        final cleanBody = body.replaceAll('"', '`"').replaceAll("'", "`'");
        Process.run('powershell', [
          '-NoProfile',
          '-Command',
          '''[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"); \$notify = New-Object System.Windows.Forms.NotifyIcon; \$notify.Icon = [System.Drawing.SystemIcons]::Information; \$notify.Visible = \$true; \$notify.ShowBalloonTip(5000, "$cleanTitle", "$cleanBody", [System.Windows.Forms.ToolTipIcon]::Info);'''
        ]);
      } catch (_) {}
    }

    const android = AndroidNotificationDetails(
      'ecosystem_transfers',
      'File Transfers',
      channelDescription: 'Notifications for incoming and outgoing file transfers',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    try {
      _notifications.show(
        safeId,
        title,
        body,
        const NotificationDetails(
          android: android,
          iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
        ),
        payload: localPath,
      );
    } catch (e) {
      logger.warning('TransferService', 'Failed to show complete notification: $e');
    }
  }

  void handleIncomingStreamProgress(Transfer transfer) {
    if (transfer.progress == null || transfer.progress!.bytesTransferred == 0) {
      SoundEffectService.instance.playIncomingAlert();
    }
    _emit(transfer);
    final prog = transfer.progress;
    if (prog != null) {
      final speedMB = (prog.speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1);
      _showNotificationProgress(
        id: transfer.transferId.hashCode,
        title: 'Receiving ${transfer.filename} ($speedMB MB/s)',
        progress: (prog.percentage * 100).toInt(),
      );
    }
  }

  void handleIncomingStreamCompleted(Transfer transfer) {
    SoundEffectService.instance.playCompletionAlert();
    _emit(transfer);
    _recordTransfer(transfer);
    _showNotificationComplete(
      id: transfer.transferId.hashCode,
      title: 'Received ${transfer.filename}',
      body: 'Saved to Downloads folder from ${transfer.peerDeviceName}',
    );
  }

  static String _guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  void dispose() {
    _progressController.close();
  }
}
