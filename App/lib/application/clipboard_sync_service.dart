// lib/application/clipboard_sync_service.dart
// Automatic universal bidirectional clipboard sync across all active ecosystem devices.
// Syncs text, screenshots, images, and links seamlessly with instant browser opening.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../core/logging/app_logger.dart';
import '../data/discovery/udp_broadcast_service.dart';
import '../data/local/daos/activity_dao.dart';
import '../data/local/daos/clipboard_dao.dart';
import '../data/local/database.dart';
import '../data/security/device_identity.dart';
import 'settings_service.dart';

class ClipboardSyncService with WidgetsBindingObserver {
  ClipboardSyncService._();
  static final ClipboardSyncService instance = ClipboardSyncService._();

  static const _channel = MethodChannel('com.localecosystem/clipboard');

  ClipboardDao? clipboardDao;
  ActivityDao? activityDao;

  Timer? _pollTimer;
  String? _lastLocalText;
  String? _lastReceivedHash;
  String? _lastImageHash;
  bool _syncing = false;

  String get lastSyncedText => _lastLocalText ?? '';

  Future<void> broadcastText(String text) async {
    await _onLocalTextDetected(text);
  }

  void start(WidgetRef? ref) {
    if (_syncing) return;
    _syncing = true;

    if (kIsWeb) return;

    WidgetsBinding.instance.addObserver(this);

    // 1. Native platform channel hook (Android callbacks)
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onClipboardChanged') {
          final text = call.arguments as String?;
          if (text != null && text.isNotEmpty) {
            _onLocalTextDetected(text);
          }
        } else if (call.method == 'onScreenshotDetected') {
          final map = call.arguments as Map<dynamic, dynamic>?;
          if (map != null) {
            final bytes = map['bytes'] as Uint8List?;
            if (bytes != null && bytes.isNotEmpty) {
              logger.info('ClipboardSync', 'Native screenshot detected (${bytes.length} bytes)! Broadcasting…');
              broadcastImageClipboard(bytes);
            }
          }
        }
      });

      // Show persistent notification
      updatePersistentNotification();

      // Check initial clipboard
      _checkAndroidNativeClipboard();

      // Store device info for the native foreground service
      _storeDeviceInfoForNative();
    }

    // 2. Continuous poller (for Linux, macOS, iOS, and fallback)
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      await _checkLocalClipboard();
      if (Platform.isLinux) {
        await _checkLinuxImageClipboard();
      }
    });

    logger.info('ClipboardSync', 'Universal bidirectional clipboard sync active');
  }

  /// Store device identity in Android SharedPreferences so the foreground service
  /// can broadcast clipboard changes even when the Flutter engine is paused.
  Future<void> _storeDeviceInfoForNative() async {
    if (!Platform.isAndroid) return;
    try {
      final identity = await DeviceIdentityService.instance.getOrCreate();
      final settings = SettingsService.instance;
      await _channel.invokeMethod('storeDeviceInfo', {
        'deviceId': identity.deviceId,
        'deviceName': settings.deviceName,
        'ecosystemId': settings.ecosystemName,
      });
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocalClipboard();
      if (Platform.isAndroid) {
        _checkAndroidNativeClipboard();
      }
      if (Platform.isLinux) {
        _checkLinuxImageClipboard();
      }
    }
  }

  Future<void> _checkAndroidNativeClipboard() async {
    try {
      final text = await _channel.invokeMethod<String>('getClipboard');
      if (text != null && text.isNotEmpty) {
        _onLocalTextDetected(text);
      }
    } catch (_) {}
  }

  Future<void> updatePersistentNotification([String? peerOrEcoName]) async {
    if (!Platform.isAndroid) return;
    try {
      final settings = SettingsService.instance;
      final target = peerOrEcoName ?? settings.ecosystemName;
      await _channel.invokeMethod('showPersistentNotification', {
        'title': 'Local Ecosystem',
        'content': 'Connected to: $target',
      });
    } catch (_) {}
  }

  Future<void> _checkLocalClipboard() async {
    try {
      String? text;
      if (Platform.isLinux) {
        // Use xclip directly — works even when app window is not focused
        final result = await Process.run(
          'xclip',
          ['-selection', 'clipboard', '-o'],
          stdoutEncoding: utf8,
        );
        if (result.exitCode == 0) {
          text = result.stdout.toString();
        }
      } else {
        // Flutter clipboard (works on iOS, macOS, etc.)
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        text = data?.text;
      }
      if (text == null || text.isEmpty) return;

      _onLocalTextDetected(text);
    } catch (_) {}
  }

  Future<void> _checkLinuxImageClipboard() async {
    if (!Platform.isLinux) return;
    try {
      final targetsResult = await Process.run('xclip', ['-selection', 'clipboard', '-t', 'TARGETS', '-o']);
      if (targetsResult.exitCode == 0 && targetsResult.stdout.toString().contains('image/png')) {
        final imgResult = await Process.run('xclip', ['-selection', 'clipboard', '-t', 'image/png', '-o'], stdoutEncoding: null);
        if (imgResult.exitCode == 0 && imgResult.stdout is List<int>) {
          final bytes = imgResult.stdout as List<int>;
          if (bytes.isNotEmpty) {
            final hash = sha256.convert(bytes).toString();
            if (hash != _lastImageHash) {
              _lastImageHash = hash;
              logger.info('ClipboardSync', 'Linux clipboard image detected (${bytes.length} bytes)! Broadcasting…');
              broadcastImageClipboard(bytes);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _onLocalTextDetected(String text) async {
    final textHash = text.hashCode.toString();
    if (text != _lastLocalText && textHash != _lastReceivedHash) {
      _lastLocalText = text;
      logger.info('ClipboardSync',
          'Local clipboard updated: "${text.length > 25 ? '${text.substring(0, 25)}…' : text}"');
      _broadcastClipboard(text);

      final identity = await DeviceIdentityService.instance.getOrCreate();
      if (clipboardDao != null) {
        try {
          await clipboardDao!.insertEvent(
            ClipboardEventTableCompanion(
              eventId: Value(const Uuid().v4()),
              sourceDeviceId: Value(identity.deviceId),
              sourceDeviceName: const Value('This Device'),
              textPreview: Value(
                  text.length > 80 ? '${text.substring(0, 80)}…' : text),
              payloadHash: Value(textHash),
              timestamp: Value(DateTime.now()),
              isLocal: const Value(true),
            ),
          );
        } catch (e) {
          logger.warning('ClipboardSync', 'Failed to record clipboard event: $e');
        }
      }
    }
  }

  Future<void> _broadcastClipboard(String text) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;

    final payload = jsonEncode({
      'type': 'CLIPBOARD_SYNC',
      'deviceId': identity.deviceId,
      'deviceName': settings.deviceName,
      'ecosystemId': settings.ecosystemName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'text': text,
    });

    final bytes = utf8.encode(payload);

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      // 1. Direct unicast to all known peer IP addresses
      for (final peerIp in UdpBroadcastService.knownPeerIps) {
        try {
          socket.send(bytes, InternetAddress(peerIp), kUdpDiscoveryPort);
        } catch (_) {}
      }

      // 2. Broadcast to global broadcast IP
      try {
        socket.send(bytes, InternetAddress('255.255.255.255'), kUdpDiscoveryPort);
      } catch (_) {}

      // 3. Broadcast across all local subnet broadcast IPs
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final broadcastIp = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              socket.send(bytes, InternetAddress(broadcastIp), kUdpDiscoveryPort);
            }
          }
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 50));
      socket.close();
    } catch (e) {
      logger.warning('ClipboardSync', 'Failed to broadcast clipboard: $e');
    }

    // Direct reliable TCP transmission to all known peers
    final tcpTextPayload = jsonEncode({
      'version': 1,
      'type': 'text_clipboard',
      'messageId': const Uuid().v4(),
      'sourceDeviceId': identity.deviceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {
        'text': text,
        'deviceName': settings.deviceName,
      },
    });

    for (final peerIp in UdpBroadcastService.knownPeerIps) {
      try {
        final client = await Socket.connect(peerIp, 51413, timeout: const Duration(seconds: 2));
        client.writeln(tcpTextPayload);
        await client.flush();
        await client.close();
      } catch (_) {}
    }
  }

  Future<void> broadcastImageClipboard(List<int> imageBytes) async {
    final imageHash = sha256.convert(imageBytes).toString();
    if (imageHash == _lastImageHash) return;
    _lastImageHash = imageHash;

    logger.info('ClipboardSync', 'Broadcasting screenshot/image (${imageBytes.length} bytes)…');

    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;

    // 1. Direct TCP streaming for 100% reliable full-resolution image delivery (no 64KB UDP limit)
    final tcpPayload = jsonEncode({
      'version': 1,
      'type': 'image_clipboard',
      'messageId': const Uuid().v4(),
      'sourceDeviceId': identity.deviceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {
        'data': base64Encode(imageBytes),
        'deviceName': settings.deviceName,
        'hash': imageHash,
      },
    });

    for (final peerIp in UdpBroadcastService.knownPeerIps) {
      try {
        final client = await Socket.connect(peerIp, 51413, timeout: const Duration(seconds: 4));
        client.writeln(tcpPayload);
        await client.flush();
        await client.close();
      } catch (_) {}
    }

    // 2. Also try UDP broadcast if small (< 45KB)
    if (imageBytes.length < 45000) {
      try {
        final payload = jsonEncode({
          'type': 'IMAGE_CLIPBOARD_SYNC',
          'deviceId': identity.deviceId,
          'deviceName': settings.deviceName,
          'ecosystemId': settings.ecosystemName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': base64Encode(imageBytes),
          'hash': imageHash,
        });
        final bytes = utf8.encode(payload);

        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket.broadcastEnabled = true;
        for (final peerIp in UdpBroadcastService.knownPeerIps) {
          try {
            socket.send(bytes, InternetAddress(peerIp), kUdpDiscoveryPort);
          } catch (_) {}
        }
        try {
          socket.send(bytes, InternetAddress('255.255.255.255'), kUdpDiscoveryPort);
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 30));
        socket.close();
      } catch (e) {
        logger.warning('ClipboardSync', 'Failed to UDP broadcast image clipboard: $e');
      }
    }
  }

  Future<void> broadcastLink(String url) async {
    logger.info('ClipboardSync', 'Broadcasting shared link: $url');

    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;

    final payload = jsonEncode({
      'type': 'LINK_SHARE',
      'deviceId': identity.deviceId,
      'deviceName': settings.deviceName,
      'ecosystemId': settings.ecosystemName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'url': url,
    });

    final bytes = utf8.encode(payload);

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      for (final peerIp in UdpBroadcastService.knownPeerIps) {
        try {
          socket.send(bytes, InternetAddress(peerIp), kUdpDiscoveryPort);
        } catch (_) {}
      }

      try {
        socket.send(bytes, InternetAddress('255.255.255.255'), kUdpDiscoveryPort);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 50));
      socket.close();
    } catch (e) {
      logger.warning('ClipboardSync', 'Failed to broadcast link: $e');
    }
  }

  Future<void> handleIncomingClipboard({
    required String senderDeviceName,
    required String senderDeviceId,
    required String text,
  }) async {
    final textHash = text.hashCode.toString();
    if (text == _lastLocalText || textHash == _lastReceivedHash) return;

    _lastReceivedHash = textHash;
    _lastLocalText = text;

    try {
      await Clipboard.setData(ClipboardData(text: text));
      logger.info('ClipboardSync',
          'Synced incoming clipboard from $senderDeviceName: "${text.length > 25 ? '${text.substring(0, 25)}…' : text}"');

      if (Platform.isAndroid) {
        try {
          await _channel.invokeMethod('showToast', {
            'message': 'Copied: $senderDeviceName',
          });
        } catch (_) {}
      } else if (Platform.isLinux) {
        try {
          await Process.run('notify-send', [
            'Local Ecosystem',
            'Copied: $senderDeviceName\n"${text.length > 50 ? '${text.substring(0, 50)}…' : text}"',
            '-i',
            '/home/aprajit/.local/share/icons/hicolor/128x128/apps/local_ecosystem.png',
          ]);
        } catch (_) {}
      }

      if (clipboardDao != null) {
        await clipboardDao!.insertEvent(
          ClipboardEventTableCompanion(
            eventId: Value(const Uuid().v4()),
            sourceDeviceId: Value(senderDeviceId),
            sourceDeviceName: Value(senderDeviceName),
            textPreview: Value(
                text.length > 80 ? '${text.substring(0, 80)}…' : text),
            payloadHash: Value(textHash),
            timestamp: Value(DateTime.now()),
            isLocal: const Value(false),
          ),
        );
      }

      if (activityDao != null) {
        await activityDao!.insertActivity(
          ActivityTableCompanion(
            entryId: Value(const Uuid().v4()),
            type: const Value('clipboard_received'),
            peerDeviceName: Value(senderDeviceName),
            description: Value(
                'Synced: "${text.length > 40 ? '${text.substring(0, 40)}…' : text}"'),
            timestamp: Value(DateTime.now()),
          ),
        );
      }
    } catch (e) {
      logger.warning('ClipboardSync', 'Failed to set clipboard: $e');
    }
  }

  Future<void> handleIncomingImageClipboard({
    required String senderDeviceName,
    required String senderDeviceId,
    required List<int> imageBytes,
  }) async {
    final imageHash = sha256.convert(imageBytes).toString();
    if (imageHash == _lastImageHash) return;
    _lastImageHash = imageHash;

    try {
      if (Platform.isLinux) {
        final tmpFile = File('/tmp/eco_clipboard_image.png');
        await tmpFile.writeAsBytes(imageBytes);
        await Process.run('xclip', [
          '-selection',
          'clipboard',
          '-t',
          'image/png',
          '-i',
          tmpFile.path,
        ]);
        logger.info('ClipboardSync',
            'Synced incoming screenshot/image from $senderDeviceName to Linux clipboard!');
        try {
          await Process.run('notify-send', [
            'Local Ecosystem',
            'Copied: $senderDeviceName (Screenshot)',
            '-i',
            '/home/aprajit/.local/share/icons/hicolor/128x128/apps/local_ecosystem.png',
          ]);
        } catch (_) {}
      } else if (Platform.isAndroid) {
        await _channel.invokeMethod('setImageClipboard', {
          'bytes': Uint8List.fromList(imageBytes),
        });
        logger.info('ClipboardSync',
            'Synced incoming screenshot/image from $senderDeviceName to Android clipboard!');
        try {
          await _channel.invokeMethod('showToast', {
            'message': 'Copied: $senderDeviceName (Screenshot)',
          });
        } catch (_) {}
      }

      if (activityDao != null) {
        await activityDao!.insertActivity(
          ActivityTableCompanion(
            entryId: Value(const Uuid().v4()),
            type: const Value('image_clipboard_received'),
            peerDeviceName: Value(senderDeviceName),
            description: Value('Synced screenshot from $senderDeviceName'),
            timestamp: Value(DateTime.now()),
          ),
        );
      }
    } catch (e) {
      logger.warning('ClipboardSync', 'Failed to set image clipboard: $e');
    }
  }

  Future<void> handleIncomingLink({
    required String senderDeviceName,
    required String url,
    String? senderDeviceId,
  }) async {
    final myDeviceId = DeviceIdentityService.instance.currentDeviceId;
    final myName = SettingsService.instance.deviceName;

    // Do NOT open link if sent by this device
    if (senderDeviceId != null && senderDeviceId.isNotEmpty && senderDeviceId == myDeviceId) {
      return;
    }
    if (senderDeviceName == myName) {
      return;
    }

    logger.info('ClipboardSync', 'Received shared link from $senderDeviceName: $url -> Auto-opening browser!');

    try {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        if (!kIsWeb && Platform.isAndroid) {
          await _channel.invokeMethod('openUrl', {'url': url});
        } else if (!kIsWeb && Platform.isLinux) {
          final env = {
            'DISPLAY': Platform.environment['DISPLAY'] ?? ':0',
            'XDG_CURRENT_DESKTOP':
                Platform.environment['XDG_CURRENT_DESKTOP'] ?? 'GNOME',
            'HOME': Platform.environment['HOME'] ?? '/home/aprajit',
            'PATH': Platform.environment['PATH'] ??
                '/usr/local/bin:/usr/bin:/bin',
          };
          if (Platform.environment.containsKey('WAYLAND_DISPLAY')) {
            env['WAYLAND_DISPLAY'] = Platform.environment['WAYLAND_DISPLAY']!;
          }
          final res = await Process.run('xdg-open', [url], environment: env);
          if (res.exitCode != 0) {
            await Process.run('google-chrome', [url], environment: env)
                .catchError((_) => Process.run('firefox', [url], environment: env));
          }
        } else if (Platform.isMacOS) {
          await Process.run('open', [url]);
        } else if (Platform.isWindows) {
          try {
            await Process.run('cmd.exe', ['/c', 'start', '', url]);
          } catch (_) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (activityDao != null) {
        await activityDao!.insertActivity(
          ActivityTableCompanion(
            entryId: Value(const Uuid().v4()),
            type: const Value('link_received'),
            peerDeviceName: Value(senderDeviceName),
            description: Value('Opened link: $url'),
            timestamp: Value(DateTime.now()),
          ),
        );
      }
    } catch (e) {
      logger.warning('ClipboardSync', 'Failed to open incoming link: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
  }
}
