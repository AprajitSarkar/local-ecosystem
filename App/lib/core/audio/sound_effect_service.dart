// lib/core/audio/sound_effect_service.dart
// Unified crystal-clear sound effect synthesizer for all platforms.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../logging/app_logger.dart';
import 'web_audio.dart';

enum SoundType {
  request,
  incoming,
  complete,
  error,
}

class SoundEffectService {
  SoundEffectService._();
  static final SoundEffectService instance = SoundEffectService._();

  static const _androidChannel =
      MethodChannel('com.localecosystem.local_ecosystem/sound_effects');

  /// Play sound when a pairing or join request arrives
  Future<void> playRequestAlert() async {
    await _playSound(SoundType.request);
  }

  /// Play pleasant "ting" chime when a file transfer starts
  Future<void> playIncomingAlert() async {
    await _playSound(SoundType.incoming);
  }

  /// Play success arpeggio/chime when a file transfer completes
  Future<void> playCompletionAlert() async {
    await _playSound(SoundType.complete);
  }

  /// Play warning/error alert
  Future<void> playErrorAlert() async {
    await _playSound(SoundType.error);
  }

  Future<void> _playSound(SoundType type) async {
    try {
      if (kIsWeb) {
        _playWebSound(type);
        return;
      }

      if (Platform.isAndroid) {
        final methodName = switch (type) {
          SoundType.request => 'playRequest',
          SoundType.incoming => 'playIncoming',
          SoundType.complete => 'playComplete',
          SoundType.error => 'playError',
        };
        try {
          await _androidChannel.invokeMethod(methodName);
        } catch (_) {
          await SystemSound.play(SystemSoundType.alert);
        }
        return;
      }

      if (Platform.isWindows) {
        try {
          final soundName = switch (type) {
            SoundType.request => 'Exclamation',
            SoundType.incoming => 'Asterisk',
            SoundType.complete => 'Beep',
            SoundType.error => 'Hand',
          };
          Process.run('powershell', [
            '-NoProfile',
            '-Command',
            '[System.Media.SystemSounds]::$soundName.Play();'
          ]);
        } catch (_) {
          await SystemSound.play(SystemSoundType.alert);
        }
        return;
      }

      // Linux / macOS / iOS
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      logger.warning('SoundEffectService', 'Could not play sound $type: $e');
    }
  }

  void _playWebSound(SoundType type) {
    switch (type) {
      case SoundType.request:
        // Pleasant alert: G5 (783.99Hz) -> C6 (1046.50Hz)
        playWebTone([783.99, 1046.50], [0.15, 0.25], volume: 0.25);
        break;
      case SoundType.incoming:
        // High crisp chime "ting": A5 (880Hz) -> E6 (1318.51Hz)
        playWebTone([880.0, 1318.51], [0.12, 0.30], volume: 0.22);
        break;
      case SoundType.complete:
        // Joyful major chord arpeggio: C5 (523.25) -> E5 (659.25) -> G5 (783.99) -> C6 (1046.50)
        playWebTone([523.25, 659.25, 783.99, 1046.50], [0.10, 0.10, 0.12, 0.35], volume: 0.25);
        break;
      case SoundType.error:
        // Low double buzz
        playWebTone([220.0, 180.0], [0.15, 0.25], volume: 0.20);
        break;
    }
  }
}
