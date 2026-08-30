// lib/core/logging/crash_reporting_service.dart
// Comprehensive crash logging, local persistence, and ecosystem-wide crash sync.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../application/settings_service.dart';
import '../../data/discovery/udp_broadcast_service.dart';
import '../../data/security/device_identity.dart';
import 'app_logger.dart';

class CrashLogEntry {
  const CrashLogEntry({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.errorSummary,
    required this.stackTrace,
    required this.timestamp,
    this.isLocal = true,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String errorSummary;
  final String stackTrace;
  final DateTime timestamp;
  final bool isLocal;

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        'errorSummary': errorSummary,
        'stackTrace': stackTrace,
        'timestamp': timestamp.toIso8601String(),
        'isLocal': isLocal,
      };

  factory CrashLogEntry.fromJson(Map<String, dynamic> json) => CrashLogEntry(
        id: json['id'] as String? ?? const Uuid().v4(),
        deviceId: json['deviceId'] as String? ?? 'unknown',
        deviceName: json['deviceName'] as String? ?? 'Device',
        platform: json['platform'] as String? ?? 'unknown',
        errorSummary: json['errorSummary'] as String? ?? 'Unknown Error',
        stackTrace: json['stackTrace'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        isLocal: json['isLocal'] as bool? ?? false,
      );
}

class CrashReportingService {
  CrashReportingService._();
  static final CrashReportingService instance = CrashReportingService._();

  final List<CrashLogEntry> _logs = [];
  final _logsController = StreamController<List<CrashLogEntry>>.broadcast();

  Stream<List<CrashLogEntry>> get logsStream => _logsController.stream;
  List<CrashLogEntry> get currentLogs => List.unmodifiable(_logs);

  static const String _kCrashStorageKey = 'local_eco_crash_logs';

  Future<void> init() async {
    await _loadSavedLogs();

    // Hook global Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportCrash(
        error: details.exceptionAsString(),
        stack: details.stack?.toString(),
      );
    };

    // Hook async Dart zone errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      reportCrash(
        error: error.toString(),
        stack: stack.toString(),
      );
      return true; // prevent hard exit if recoverable
    };

    logger.info('CrashReporter', 'Crash reporting initialized (${_logs.length} stored logs)');
  }

  Future<void> reportCrash({
    required String error,
    String? stack,
  }) async {
    final settings = SettingsService.instance;
    final identity = await DeviceIdentityService.instance.getOrCreate();

    final entry = CrashLogEntry(
      id: const Uuid().v4(),
      deviceId: identity.deviceId,
      deviceName: settings.deviceName,
      platform: _currentPlatform(),
      errorSummary: error,
      stackTrace: stack ?? StackTrace.current.toString(),
      timestamp: DateTime.now(),
      isLocal: true,
    );

    _logs.insert(0, entry);
    if (_logs.length > 100) _logs.removeLast(); // keep last 100
    _logsController.add(List.unmodifiable(_logs));

    await _saveLogs();
    await _broadcastCrashLog(entry);
    logger.error('CrashReporter', 'Crash logged: $error');
  }

  Future<void> recordRemoteCrash(CrashLogEntry remoteEntry) async {
    if (_logs.any((l) => l.id == remoteEntry.id)) return;

    _logs.insert(0, remoteEntry);
    if (_logs.length > 100) _logs.removeLast();
    _logsController.add(List.unmodifiable(_logs));

    await _saveLogs();
    logger.warning('CrashReporter',
        'Received remote crash log from ${remoteEntry.deviceName} (${remoteEntry.platform})');
  }

  Future<void> clearLogs() async {
    _logs.clear();
    _logsController.add([]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCrashStorageKey);
  }

  Future<void> _loadSavedLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kCrashStorageKey);
      if (raw != null) {
        _logs.clear();
        for (final item in raw) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          _logs.add(CrashLogEntry.fromJson(map));
        }
        _logsController.add(List.unmodifiable(_logs));
      }
    } catch (e) {
      logger.warning('CrashReporter', 'Failed to load saved crash logs: $e');
    }
  }

  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _logs.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_kCrashStorageKey, list);
    } catch (e) {
      logger.warning('CrashReporter', 'Failed to persist crash logs: $e');
    }
  }

  Future<void> _broadcastCrashLog(CrashLogEntry entry) async {
    if (kIsWeb) return;
    try {
      final payload = jsonEncode({
        'type': 'CRASH_LOG_SYNC',
        'id': entry.id,
        'deviceId': entry.deviceId,
        'deviceName': entry.deviceName,
        'platform': entry.platform,
        'errorSummary': entry.errorSummary,
        'stackTrace': entry.stackTrace,
        'timestamp': entry.timestamp.toIso8601String(),
      });
      final bytes = utf8.encode(payload);

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(bytes, InternetAddress('255.255.255.255'), kUdpDiscoveryPort);

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

      await Future.delayed(const Duration(milliseconds: 50));
      socket.close();
    } catch (e) {
      logger.warning('CrashReporter', 'Failed to broadcast crash log: $e');
    }
  }

  static String _currentPlatform() {
    if (kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'Android (Web)';
        case TargetPlatform.iOS:
          return 'iOS (Web)';
        case TargetPlatform.windows:
          return 'Windows (Web)';
        case TargetPlatform.macOS:
          return 'macOS (Web)';
        case TargetPlatform.linux:
          return 'Linux (Web)';
        default:
          return 'Web Browser';
      }
    }
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    return 'Other';
  }
}
