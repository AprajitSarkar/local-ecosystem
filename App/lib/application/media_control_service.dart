// lib/application/media_control_service.dart
// Real-time remote media playback status sync and controls (Play, Pause, Next, Prev, Volume).

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/logging/app_logger.dart';
import '../data/discovery/udp_broadcast_service.dart';
import '../data/security/device_identity.dart';
import 'settings_service.dart';

class RemoteMediaState {
  final String deviceId;
  final String deviceName;
  final String title;
  final String artist;
  final String album;
  final bool isPlaying;
  final int durationMs;
  final int positionMs;
  final DateTime updatedAt;

  RemoteMediaState({
    required this.deviceId,
    required this.deviceName,
    required this.title,
    required this.artist,
    required this.album,
    required this.isPlaying,
    this.durationMs = 0,
    this.positionMs = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory RemoteMediaState.fromJson(Map<String, dynamic> json) => RemoteMediaState(
        deviceId: json['deviceId'] as String? ?? '',
        deviceName: json['deviceName'] as String? ?? 'Device',
        title: json['title'] as String? ?? 'Playing Media',
        artist: json['artist'] as String? ?? '',
        album: json['album'] as String? ?? '',
        isPlaying: json['isPlaying'] as bool? ?? false,
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'title': title,
        'artist': artist,
        'album': album,
        'isPlaying': isPlaying,
        'durationMs': durationMs,
        'positionMs': positionMs,
      };
}

class MediaControlService extends ChangeNotifier {
  MediaControlService._();
  static final MediaControlService instance = MediaControlService._();

  static const _channel = MethodChannel('com.localecosystem/media');

  RemoteMediaState? _activeMedia;
  RemoteMediaState? get activeMedia => _activeMedia;

  bool _initialized = false;

  void init() {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    if (Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onMediaPlaybackChanged') {
          final data = call.arguments as Map<dynamic, dynamic>?;
          if (data != null) {
            final title = data['title'] as String? ?? '';
            final artist = data['artist'] as String? ?? '';
            final album = data['album'] as String? ?? '';
            final isPlaying = data['isPlaying'] as bool? ?? false;
            broadcastLocalMediaState(
              title: title,
              artist: artist,
              album: album,
              isPlaying: isPlaying,
            );
          }
        }
      });
    }
  }

  Future<void> broadcastLocalMediaState({
    required String title,
    required String artist,
    required String album,
    required bool isPlaying,
  }) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;

    final mediaState = RemoteMediaState(
      deviceId: identity.deviceId,
      deviceName: settings.deviceName,
      title: title,
      artist: artist,
      album: album,
      isPlaying: isPlaying,
    );

    _activeMedia = mediaState;
    notifyListeners();

    final payload = jsonEncode({
      'type': 'MEDIA_STATE',
      ...mediaState.toJson(),
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
    } catch (_) {}
  }

  void handleIncomingMediaState(Map<String, dynamic> data) {
    _activeMedia = RemoteMediaState.fromJson(data);
    logger.info('MediaControl', 'Received media update: "${_activeMedia?.title}" (${_activeMedia?.isPlaying == true ? 'Playing' : 'Paused'})');
    notifyListeners();
  }

  Future<void> sendMediaCommand({
    required String targetAddress,
    required String action, // PLAY_PAUSE, NEXT, PREVIOUS, VOLUME_UP, VOLUME_DOWN
  }) async {
    final payload = jsonEncode({
      'type': 'MEDIA_COMMAND',
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final bytes = utf8.encode(payload);

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(bytes, InternetAddress(targetAddress), kUdpDiscoveryPort);
      await Future.delayed(const Duration(milliseconds: 50));
      socket.close();
      logger.info('MediaControl', 'Sent media command "$action" to $targetAddress');
    } catch (e) {
      logger.warning('MediaControl', 'Failed to send media command: $e');
    }
  }

  Future<void> handleIncomingMediaCommand(String action) async {
    logger.info('MediaControl', 'Executing local media command: $action');
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('executeMediaCommand', {'action': action});
      } catch (_) {}
    }
  }
}
