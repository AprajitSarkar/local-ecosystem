// lib/application/notification_mirror_service.dart
// Real-time cross-device notification mirroring with automated OTP detection and 1-tap copy.

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import '../core/logging/app_logger.dart';
import '../data/discovery/udp_broadcast_service.dart';
import '../data/local/daos/activity_dao.dart';
import '../data/local/database.dart';
import '../data/security/device_identity.dart';
import 'settings_service.dart';

class NotificationMirrorService {
  NotificationMirrorService._();
  static final NotificationMirrorService instance = NotificationMirrorService._();

  static const _channel = MethodChannel('com.localecosystem/notifications');
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  ActivityDao? activityDao;
  bool _initialized = false;

  final List<Map<String, dynamic>> _mirroredNotifications = [];
  List<Map<String, dynamic>> get mirroredNotifications => List.unmodifiable(_mirroredNotifications);

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    // Initialize local desktop notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      macOS: DarwinInitializationSettings(),
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              'mirrored_notifications',
              'Mirrored Notifications',
              description: 'Real-time cross-device notifications and OTPs',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
          await androidPlugin.requestNotificationsPermission();
        }
      }
    } catch (_) {}

    // Android native notification listener callback
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationReceived') {
          final data = call.arguments as Map<dynamic, dynamic>?;
          if (data != null) {
            final appName = data['appName'] as String? ?? 'App';
            final title = data['title'] as String? ?? '';
            final text = data['text'] as String? ?? '';
            if (title.isNotEmpty || text.isNotEmpty) {
              broadcastNotification(
                appName: appName,
                title: title,
                text: text,
              );
            }
          }
        }
      });
    }
  }

  /// Broadcasts notification to all active devices on the local ecosystem
  Future<void> broadcastNotification({
    required String appName,
    required String title,
    required String text,
  }) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;
    final otp = _extractOtp(text) ?? _extractOtp(title);

    final payload = jsonEncode({
      'type': 'NOTIFICATION_MIRROR',
      'deviceId': identity.deviceId,
      'deviceName': settings.deviceName,
      'appName': appName,
      'title': title,
      'text': text,
      'isOtp': otp != null,
      'otpCode': otp,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
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
      logger.info('NotificationMirror', 'Broadcasted notification from $appName: "$title"');
    } catch (e) {
      logger.warning('NotificationMirror', 'Failed to broadcast notification: $e');
    }
  }

  /// Handles incoming mirrored notification from a remote device
  Future<void> handleIncomingNotification({
    required String senderDeviceName,
    required String appName,
    required String title,
    required String text,
    String? otpCode,
  }) async {
    final notifItem = {
      'id': const Uuid().v4(),
      'senderDeviceName': senderDeviceName,
      'appName': appName,
      'title': title,
      'text': text,
      'otpCode': otpCode,
      'timestamp': DateTime.now(),
    };

    _mirroredNotifications.insert(0, notifItem);
    if (_mirroredNotifications.length > 50) _mirroredNotifications.removeLast();

    logger.info('NotificationMirror', 'Received notification from $senderDeviceName ($appName): "$title"');

    // If OTP detected, auto-copy to clipboard if user configured or show notice
    if (otpCode != null && otpCode.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: otpCode));
      logger.info('NotificationMirror', '🔑 Auto-copied OTP to clipboard: $otpCode');
    }

    final notifTitle = otpCode != null
        ? '🔑 OTP: $otpCode ($appName on $senderDeviceName)'
        : '$appName • $senderDeviceName';
    final notifBody = title.isNotEmpty ? '$title\n$text' : text;

    // Display local desktop notification
    if (Platform.isWindows) {
      try {
        final cleanTitle = notifTitle.replaceAll('"', '`"').replaceAll("'", "`'");
        final cleanBody = notifBody.replaceAll('"', '`"').replaceAll("'", "`'");
        Process.run('powershell', [
          '-NoProfile',
          '-Command',
          '''[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"); \$notify = New-Object System.Windows.Forms.NotifyIcon; \$notify.Icon = [System.Drawing.SystemIcons]::Information; \$notify.Visible = \$true; \$notify.ShowBalloonTip(5000, "$cleanTitle", "$cleanBody", [System.Windows.Forms.ToolTipIcon]::Info);'''
        ]);
      } catch (_) {}
    } else {
      try {
        const details = NotificationDetails(
          android: AndroidNotificationDetails(
            'mirrored_notifications',
            'Mirrored Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          linux: LinuxNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        );

        await _notificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notifTitle,
          notifBody,
          details,
        );
      } catch (e) {
        logger.warning('NotificationMirror', 'Failed to display notification banner: $e');
      }
    }

    // Record in activity log
    if (activityDao != null) {
      try {
        await activityDao!.insertActivity(
          ActivityTableCompanion(
            entryId: Value(const Uuid().v4()),
            type: const Value('notification_mirrored'),
            description: Value('$appName notification: $title'),
            peerDeviceName: Value(senderDeviceName),
            timestamp: Value(DateTime.now()),
          ),
        );
      } catch (_) {}
    }
  }

  static String? _extractOtp(String input) {
    if (input.isEmpty) return null;
    // Match common OTP patterns (4 to 8 digits with surrounding keywords like code, OTP, verification, password)
    final otpRegex = RegExp(r'\b(?:code|otp|verification|password|pin|is)?\s*[:#\s]?\s*([0-9]{4,8})\b', caseSensitive: false);
    final match = otpRegex.firstMatch(input);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  String? extractOtpForTesting(String input) => _extractOtp(input);
}
