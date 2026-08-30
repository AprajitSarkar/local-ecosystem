// lib/application/web_portal_server.dart
// Embedded, zero-configuration LAN HTTP Web Portal Server.
// Automatically runs on whichever device is active (Linux PC, Android Phone, Windows PC)
// so that iPad / iPhone or any browser on the local Wi-Fi can connect immediately.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../core/audio/sound_effect_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/adaptive_throughput_tuner.dart';
import '../data/discovery/mdns_service.dart';
import '../data/security/device_identity.dart';
import '../domain/entities/transfer.dart';
import 'clipboard_sync_service.dart';
import 'pairing_service.dart';
import 'settings_service.dart';
import 'transfer_service.dart';

class _WebPairingRequest {
  _WebPairingRequest({
    required this.requestId,
    required this.hostName,
    required this.hostDeviceId,
    required this.ecosystemName,
    required this.ecosystemId,
    required this.completer,
  });

  final String requestId;
  final String hostName;
  final String hostDeviceId;
  final String ecosystemName;
  final String ecosystemId;
  final Completer<bool> completer;
}

class PendingWebDownload {
  final String transferId;
  final String filename;
  final String filePath;
  final int totalBytes;
  final String? targetDeviceId;
  final DateTime stagedAt;

  PendingWebDownload({
    required this.transferId,
    required this.filename,
    required this.filePath,
    required this.totalBytes,
    this.targetDeviceId,
    DateTime? stagedAt,
  }) : stagedAt = stagedAt ?? DateTime.now();
}

class WebPortalServer extends ChangeNotifier {
  WebPortalServer._();
  static final WebPortalServer instance = WebPortalServer._();

  HttpServer? _server;
  int _port = 8080;
  String _lanIp = '127.0.0.1';
  bool _isRunning = false;
  final Map<String, Map<String, dynamic>> _activeWebPeers = {};
  final Map<String, _WebPairingRequest> _pendingWebPairings = {};
  final Map<String, PendingWebDownload> _pendingDownloads = {};
  void Function(DiscoveredPeer peer)? onWebPeerDiscovered;
  PairingService? pairingService;
  TransferService? transferService;

  Map<String, dynamic>? getWebPeer(String deviceId) => _activeWebPeers[deviceId];
  bool get isRunning => _isRunning;
  int get port => _port;
  String get lanIp => _lanIp;
  String get portalUrl => 'http://$_lanIp:$_port';
  String get localDomainUrl => 'http://ecosystem.local:$_port';

  void stageFileForWebDownload({
    required String transferId,
    required String filename,
    required String filePath,
    required int totalBytes,
    String? targetDeviceId,
  }) {
    _pendingDownloads[transferId] = PendingWebDownload(
      transferId: transferId,
      filename: filename,
      filePath: filePath,
      totalBytes: totalBytes,
      targetDeviceId: targetDeviceId,
    );
    logger.info('WebPortalServer', 'Staged file for Web download: "$filename" ($transferId)');
  }

  Future<bool> requestWebClientPairing({
    required String targetDeviceId,
    required String hostName,
    required String hostDeviceId,
    required String ecosystemName,
    required String ecosystemId,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final reqId = const Uuid().v4();
    final completer = Completer<bool>();
    _pendingWebPairings[targetDeviceId] = _WebPairingRequest(
      requestId: reqId,
      hostName: hostName,
      hostDeviceId: hostDeviceId,
      ecosystemName: ecosystemName,
      ecosystemId: ecosystemId,
      completer: completer,
    );
    try {
      return await completer.future.timeout(timeout);
    } catch (_) {
      _pendingWebPairings.remove(targetDeviceId);
      return false;
    }
  }

  Future<void> start() async {
    if (kIsWeb) return; // Web clients don't host themselves
    if (_isRunning) return;

    await _detectLanIp();

    for (int p = 8080; p <= 8090; p++) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, p);
        _port = p;
        _isRunning = true;
        break;
      } catch (_) {
        continue;
      }
    }

    if (_server == null) {
      logger.warning('WebPortalServer', 'Failed to bind ports 8080-8090. Trying dynamic port.');
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        _port = _server!.port;
        _isRunning = true;
      } catch (e) {
        logger.error('WebPortalServer', 'Could not start embedded web portal: $e');
        return;
      }
    }

    logger.info('WebPortalServer', '🚀 Embedded Web Portal live at: $portalUrl');
    notifyListeners();

    _server!.listen(_handleRequest, onError: (e) {
      logger.warning('WebPortalServer', 'Server error: $e');
    });
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> _detectLanIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('127.')) {
            // Prioritize standard local Wi-Fi ranges (192.168.x.x, 10.x.x.x, 172.16.x.x)
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.')) {
              _lanIp = addr.address;
              return;
            }
            _lanIp = addr.address;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final res = request.response;

    // Permissive CORS & PWA headers for universal device support
    res.headers.set('Access-Control-Allow-Origin', '*');
    res.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.headers.set('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization, X-Filename');

    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.ok;
      await res.close();
      return;
    }

    final path = request.uri.path;

    // ─── API Endpoints ────────────────────────────────────────────────────────
    if (path == '/api/status') {
      final settings = SettingsService.instance;
      final payload = {
        'status': 'online',
        'hostDeviceName': settings.deviceName,
        'ecosystemName': settings.ecosystemName,
        'ecosystemId': settings.ecosystemId,
        'deviceId': DeviceIdentityService.instance.currentDeviceId,
        'clipboardSync': settings.clipboardSyncEnabled,
        'platform': Platform.operatingSystem,
        'lanIp': _lanIp,
        'portalPort': _port,
      };
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode(payload));
      await res.close();
      return;
    }

    if (path == '/api/peers' && request.method == 'GET') {
      final settings = SettingsService.instance;
      final peersList = <Map<String, dynamic>>[];

      // Always include host device
      peersList.add({
        'deviceId': DeviceIdentityService.instance.currentDeviceId,
        'displayName': '${settings.deviceName} (Host)',
        'platform': Platform.operatingSystem,
        'address': _lanIp,
        'port': _port,
        'isOnline': true,
        'isHost': true,
      });

      // Include all registered web clients and discovered peers
      for (final p in _activeWebPeers.values) {
        peersList.add(p);
      }

      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({'peers': peersList}));
      await res.close();
      return;
    }

    if (path == '/api/web_peer' && request.method == 'POST') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final peerId = data['deviceId'] as String? ?? 'web-${request.connectionInfo?.remoteAddress.address}';
        final peerName = data['displayName'] as String? ?? 'Web Device (iPad)';
        final platform = data['platform'] as String? ?? 'ios';
        final clientIp = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';

        _activeWebPeers[peerId] = {
          'deviceId': peerId,
          'displayName': peerName,
          'platform': platform,
          'address': clientIp,
          'port': _port,
          'isOnline': true,
          'isHost': false,
          'lastSeen': DateTime.now().toIso8601String(),
        };

        // Notify discovery service
        onWebPeerDiscovered?.call(DiscoveredPeer(
          deviceId: peerId,
          displayName: peerName,
          platform: platform,
          address: clientIp,
          port: _port,
          protocolVersion: 1,
          ecosystemHint: SettingsService.instance.ecosystemName,
          capabilities: ['clipboard', 'file', 'link'],
        ));

        logger.info('WebPortalServer', 'Registered Web Client Peer: $peerName @ $clientIp');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'success': true}));
      } catch (e) {
        res.statusCode = HttpStatus.badRequest;
        res.write(jsonEncode({'error': e.toString()}));
      }
      await res.close();
      return;
    }

    if (path == '/api/pairing_pending' && request.method == 'GET') {
      final deviceId = request.uri.queryParameters['deviceId'] ?? '';
      final pending = _pendingWebPairings[deviceId];
      res.headers.contentType = ContentType.json;
      if (pending != null) {
        res.write(jsonEncode({
          'hasPending': true,
          'requestId': pending.requestId,
          'hostName': pending.hostName,
          'hostDeviceId': pending.hostDeviceId,
          'ecosystemName': pending.ecosystemName,
          'ecosystemId': pending.ecosystemId,
        }));
      } else {
        res.write(jsonEncode({'hasPending': false}));
      }
      await res.close();
      return;
    }

    if (path == '/api/pairing_respond' && request.method == 'POST') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final deviceId = data['deviceId'] as String? ?? '';
        final approved = data['approved'] as bool? ?? false;
        final pending = _pendingWebPairings.remove(deviceId);
        if (pending != null && !pending.completer.isCompleted) {
          pending.completer.complete(approved);
        }
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'success': true}));
      } catch (e) {
        res.statusCode = HttpStatus.badRequest;
        res.write(jsonEncode({'error': e.toString()}));
      }
      await res.close();
      return;
    }

    if (path == '/api/join_request' && request.method == 'POST') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final clientName = data['displayName'] as String? ?? 'Web Browser';
        final clientPlatform = data['platform'] as String? ?? 'web';
        final clientDeviceId = data['deviceId'] as String? ?? 'web-client-${DateTime.now().millisecondsSinceEpoch}';
        final clientIp = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
        final settings = SettingsService.instance;

        // Register web peer as active
        final peer = DiscoveredPeer(
          deviceId: clientDeviceId,
          displayName: clientName,
          platform: clientPlatform,
          address: clientIp,
          port: _port,
          protocolVersion: 1,
          ecosystemHint: settings.ecosystemName,
          capabilities: ['clipboard', 'file', 'link'],
        );
        onWebPeerDiscovered?.call(peer);

        final responseCompleter = Completer<bool>();
        if (pairingService != null) {
          final incomingReq = IncomingPairingRequest(
            messageId: const Uuid().v4(),
            sourceDeviceId: clientDeviceId,
            displayName: clientName,
            platform: clientPlatform,
            publicKey: '',
            ecosystemId: settings.ecosystemId,
            ecosystemName: settings.ecosystemName,
            respondWith: (approved) async {
              if (!responseCompleter.isCompleted) {
                responseCompleter.complete(approved);
              }
            },
          );
          SoundEffectService.instance.playRequestAlert();
          pairingService!.emitIncomingRequest(incomingReq);

          final approved = await responseCompleter.future.timeout(
            const Duration(seconds: 45),
            onTimeout: () => false,
          );

          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({
            'approved': approved,
            'ecosystemName': settings.ecosystemName,
            'ecosystemId': settings.ecosystemId,
            'hostDeviceName': settings.deviceName,
            'hostDeviceId': DeviceIdentityService.instance.currentDeviceId,
            'platform': Platform.operatingSystem,
          }));
        } else {
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({
            'approved': true,
            'ecosystemName': settings.ecosystemName,
            'ecosystemId': settings.ecosystemId,
            'hostDeviceName': settings.deviceName,
            'hostDeviceId': DeviceIdentityService.instance.currentDeviceId,
            'platform': Platform.operatingSystem,
          }));
        }
      } catch (e) {
        res.statusCode = HttpStatus.badRequest;
        res.write(jsonEncode({'error': e.toString()}));
      }
      await res.close();
      return;
    }

    if (path == '/api/join_ecosystem' && request.method == 'POST') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final clientName = data['displayName'] as String? ?? 'Web Browser';
        final clientPlatform = data['platform'] as String? ?? 'web';
        final clientDeviceId = data['deviceId'] as String? ?? 'web-client-${DateTime.now().millisecondsSinceEpoch}';
        final clientIp = request.connectionInfo?.remoteAddress.address ?? '127.0.0.1';
        final settings = SettingsService.instance;

        // Register web peer as active
        final peer = DiscoveredPeer(
          deviceId: clientDeviceId,
          displayName: clientName,
          platform: clientPlatform,
          address: clientIp,
          port: _port,
          protocolVersion: 1,
          ecosystemHint: settings.ecosystemName,
          capabilities: ['clipboard', 'file', 'link'],
        );
        onWebPeerDiscovered?.call(peer);

        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({
          'success': true,
          'ecosystemName': settings.ecosystemName,
          'ecosystemId': settings.ecosystemId,
          'hostDeviceName': settings.deviceName,
          'hostDeviceId': DeviceIdentityService.instance.currentDeviceId,
        }));
      } catch (e) {
        res.statusCode = HttpStatus.badRequest;
        res.write(jsonEncode({'error': e.toString()}));
      }
      await res.close();
      return;
    }

    if (path == '/api/share_link' && request.method == 'POST') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final data = jsonDecode(bodyStr) as Map<String, dynamic>;
        final url = data['url'] as String? ?? '';
        final senderName = data['senderName'] as String? ?? 'Web User';
        if (url.isNotEmpty) {
          await ClipboardSyncService.instance.handleIncomingLink(
            senderDeviceName: senderName,
            url: url,
          );
        }
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'success': true}));
      } catch (e) {
        res.statusCode = HttpStatus.badRequest;
        res.write(jsonEncode({'error': e.toString()}));
      }
      await res.close();
      return;
    }

    if ((path == '/download/android' || path == '/local_ecosystem.apk' || path == '/api/download_apk') && request.method == 'GET') {
      final apkCandidates = [
        '/home/aprajit/Cozmo/ipad/build_artifacts/android/local_ecosystem.apk',
        '/home/aprajit/Cozmo/ipad/App/build/app/outputs/flutter-apk/app-release.apk',
      ];
      File? apkFile;
      for (final p in apkCandidates) {
        final f = File(p);
        if (f.existsSync()) {
          apkFile = f;
          break;
        }
      }
      if (apkFile != null) {
        res.headers.contentType = ContentType('application', 'vnd.android.package-archive');
        res.headers.set('Content-Disposition', 'attachment; filename="local_ecosystem.apk"');
        res.headers.contentLength = apkFile.lengthSync();
        await res.addStream(apkFile.openRead());
      } else {
        res.statusCode = HttpStatus.notFound;
        res.write('APK file not found');
      }
      await res.close();
      return;
    }

    if (path == '/api/pending_downloads' && request.method == 'GET') {
      final deviceId = request.uri.queryParameters['deviceId'] ?? '';
      final list = <Map<String, dynamic>>[];
      for (final item in _pendingDownloads.values) {
        // Broadcast to all web clients or targeted to this web client
        final target = item.targetDeviceId ?? '';
        final isMatch = target.isEmpty ||
            target == 'ECOSYSTEM' ||
            target == deviceId ||
            target.startsWith('web') && (deviceId.startsWith('web') || deviceId.isEmpty);
        if (isMatch) {
          list.add({
            'transferId': item.transferId,
            'filename': item.filename,
            'totalBytes': item.totalBytes,
            'downloadUrl': '/api/download_file?id=${item.transferId}',
          });
        }
      }
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({'downloads': list}));
      await res.close();
      return;
    }

    if (path == '/api/download_file' && request.method == 'GET') {
      final transferId = request.uri.queryParameters['id'] ?? '';
      final item = _pendingDownloads[transferId];
      if (item != null) {
        final file = File(item.filePath);
        if (await file.exists()) {
          final ext = p.extension(item.filename).toLowerCase();
          res.headers.contentType = _getContentType(ext);
          res.headers.set(
            'Content-Disposition',
            'attachment; filename="${Uri.encodeComponent(item.filename)}"; filename*=UTF-8\'\'${Uri.encodeComponent(item.filename)}',
          );
          res.headers.contentLength = await file.length();
          await res.addStream(file.openRead());
          await res.close();
          return;
        }
      }
      res.statusCode = HttpStatus.notFound;
      res.write('File not found');
      await res.close();
      return;
    }

    if ((path == '/api/transfer_stream' || path == '/api/upload') && request.method == 'POST') {
      try {
        final transferId = request.headers.value('X-Transfer-Id') ?? const Uuid().v4();
        final rawFilename = request.headers.value('X-Filename') ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
        final filename = Uri.decodeComponent(rawFilename);
        final totalBytesStr = request.headers.value('X-Total-Bytes');
        final totalBytes = int.tryParse(totalBytesStr ?? '') ?? 0;
        final senderDeviceId = request.headers.value('X-Sender-Device-Id') ?? 'web-client';
        final rawSenderName = request.headers.value('X-Sender-Device-Name') ?? 'Web Browser';
        final senderName = Uri.decodeComponent(rawSenderName);

        final recvFolder = await SettingsService.instance.getReceiveFolder();
        final destDir = Directory(recvFolder);
        if (!await destDir.exists()) await destDir.create(recursive: true);

        var finalFile = File(p.join(recvFolder, filename));
        int counter = 1;
        while (await finalFile.exists()) {
          final dot = filename.lastIndexOf('.');
          if (dot != -1) {
            final base = filename.substring(0, dot);
            final ext = filename.substring(dot);
            finalFile = File(p.join(recvFolder, '$base ($counter)$ext'));
          } else {
            finalFile = File(p.join(recvFolder, '$filename ($counter)'));
          }
          counter++;
        }

        final sink = finalFile.openWrite(mode: FileMode.write);
        int bytesReceived = 0;
        final tuner = AdaptiveThroughputTuner(
          totalBytes: totalBytes,
          initialChunkSizeBytes: 1024 * 1024,
          maxChunkSizeBytes: 8 * 1024 * 1024,
        );

        final transfer = Transfer(
          transferId: transferId,
          filename: filename,
          mimeType: _getContentType(p.extension(filename)).mimeType,
          totalBytes: totalBytes,
          direction: TransferDirection.incoming,
          peerDeviceId: senderDeviceId,
          peerDeviceName: senderName,
          state: TransferState.transferring,
          startedAt: DateTime.now(),
          localPath: finalFile.path,
        );
        transferService?.handleIncomingStreamProgress(transfer);
        SoundEffectService.instance.playIncomingAlert();

        DateTime lastUiUpdate = DateTime.now();
        await for (final chunk in request) {
          sink.add(chunk);
          bytesReceived += chunk.length;
          tuner.recordProgress(chunk.length);

          final now = DateTime.now();
          if (now.difference(lastUiUpdate).inMilliseconds >= 120 || bytesReceived == totalBytes) {
            lastUiUpdate = now;
            final snap = tuner.getSnapshot();
            final eta = snap.speedBytesPerSec > 0
                ? ((totalBytes - bytesReceived) / snap.speedBytesPerSec).round()
                : null;

            transferService?.handleIncomingStreamProgress(transfer.copyWith(
              state: TransferState.transferring,
              progress: TransferProgress(
                bytesTransferred: bytesReceived,
                totalBytes: totalBytes > 0 ? totalBytes : bytesReceived,
                speedBytesPerSec: snap.speedBytesPerSec,
                etaSeconds: eta,
              ),
            ));
          }
        }
        await sink.flush();
        await sink.close();

        final completed = transfer.copyWith(
          state: TransferState.completed,
          completedAt: DateTime.now(),
          totalBytes: bytesReceived,
          localPath: finalFile.path,
        );
        transferService?.handleIncomingStreamCompleted(completed);
        SoundEffectService.instance.playCompletionAlert();

        // Stage file for any connected web client (iPad / Browser PWA)
        stageFileForWebDownload(
          transferId: transferId,
          filename: filename,
          filePath: finalFile.path,
          totalBytes: bytesReceived,
        );

        logger.info('WebPortalServer', 'File received successfully: ${finalFile.path} ($bytesReceived bytes)');
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'success': true, 'path': finalFile.path, 'filename': filename}));
      } catch (e) {
        logger.error('WebPortalServer', 'Stream upload error', e);
        res.statusCode = HttpStatus.internalServerError;
        res.write(jsonEncode({'error': e.toString()}));
      }
      await res.close();
      return;
    }

    // ─── Static Assets (Flutter Web Bundle) ──────────────────────────────────
    String assetPath = path == '/' ? 'index.html' : (path.startsWith('/') ? path.substring(1) : path);

    // Try loading from rootBundle assets/web_portal/...
    try {
      final bundleKey = 'assets/web_portal/$assetPath';
      ByteData? byteData;
      try {
        byteData = await rootBundle.load(bundleKey);
      } catch (_) {
        // Fallback for SPA routing to index.html
        byteData = await rootBundle.load('assets/web_portal/index.html');
        assetPath = 'index.html';
      }

      final ext = p.extension(assetPath).toLowerCase();
      res.headers.contentType = _getContentType(ext);

      if (assetPath.endsWith('.js') || assetPath.endsWith('.wasm') || assetPath.endsWith('.png')) {
        res.headers.set('Cache-Control', 'public, max-age=3600');
      } else {
        res.headers.set('Cache-Control', 'no-cache');
      }

      res.add(byteData.buffer.asUint8List());
    } catch (e) {
      res.statusCode = HttpStatus.notFound;
      res.write('Not found');
    }

    await res.close();
  }

  ContentType _getContentType(String ext) {
    switch (ext) {
      case '.html':
        return ContentType.html;
      case '.js':
        return ContentType('application', 'javascript', charset: 'utf-8');
      case '.json':
        return ContentType.json;
      case '.css':
        return ContentType('text', 'css', charset: 'utf-8');
      case '.png':
        return ContentType('image', 'png');
      case '.jpg':
      case '.jpeg':
        return ContentType('image', 'jpeg');
      case '.svg':
        return ContentType('image', 'svg+xml');
      case '.wasm':
        return ContentType('application', 'wasm');
      case '.otf':
        return ContentType('font', 'otf');
      case '.ttf':
        return ContentType('font', 'ttf');
      case '.woff':
        return ContentType('font', 'woff');
      case '.woff2':
        return ContentType('font', 'woff2');
      default:
        return ContentType.binary;
    }
  }
}
