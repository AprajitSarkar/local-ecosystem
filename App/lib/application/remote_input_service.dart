// lib/application/remote_input_service.dart
// Low-latency remote touchpad & keyboard input service (Zorin Connect / KDE Connect style).
// Controls mouse cursor, gestures, clicks, scrolling, and keyboard typing on Windows PC.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import '../data/discovery/udp_broadcast_service.dart';
import 'native_input_helper.dart';

const kRemoteInputUdpPort = 42422;

class RemoteInputService {
  RemoteInputService._();
  static final RemoteInputService instance = RemoteInputService._();

  RawDatagramSocket? _udpReceiver;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    if (!kIsWeb && Platform.isWindows) {
      NativeInputHelper.init();
      _startUdpReceiver();
    }
  }

  Future<void> _startUdpReceiver() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      _udpReceiver = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kRemoteInputUdpPort,
        reuseAddress: true,
      );
      _udpReceiver!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpReceiver!.receive();
          if (datagram != null) {
            try {
              final jsonStr = utf8.decode(datagram.data);
              final map = jsonDecode(jsonStr) as Map<String, dynamic>;
              handleIncomingInputEvent(map);
            } catch (_) {}
          }
        }
      });
      logger.info('RemoteInput', 'Windows Remote Input Receiver active on UDP port $kRemoteInputUdpPort');
    } catch (e) {
      logger.warning('RemoteInput', 'Failed to bind remote input UDP socket: $e');
    }
  }

  void handleIncomingInputEvent(Map<String, dynamic> event) {
    if (kIsWeb || !Platform.isWindows) return;

    final type = event['type'] as String?;
    switch (type) {
      case 'MOUSE_MOVE':
        final dx = (event['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (event['dy'] as num?)?.toDouble() ?? 0.0;
        NativeInputHelper.moveMouse(dx, dy);
        break;

      case 'MOUSE_CLICK':
        final button = event['button'] as String? ?? 'left';
        NativeInputHelper.clickMouse(button: button, isDown: true);
        NativeInputHelper.clickMouse(button: button, isDown: false);
        break;

      case 'MOUSE_SCROLL':
        final dy = (event['dy'] as num?)?.toDouble() ?? 0.0;
        final scrollAmount = (dy * 25).round();
        NativeInputHelper.scrollMouse(scrollAmount);
        break;

      case 'KEY_INPUT':
        final text = event['text'] as String?;
        final key = event['key'] as String?;
        if (key != null) {
          switch (key) {
            case 'ENTER':
              NativeInputHelper.keyEvent(keyCode: 0x0D, isUp: false);
              NativeInputHelper.keyEvent(keyCode: 0x0D, isUp: true);
              break;
            case 'BACKSPACE':
              NativeInputHelper.keyEvent(keyCode: 0x08, isUp: false);
              NativeInputHelper.keyEvent(keyCode: 0x08, isUp: true);
              break;
            case 'TAB':
              NativeInputHelper.keyEvent(keyCode: 0x09, isUp: false);
              NativeInputHelper.keyEvent(keyCode: 0x09, isUp: true);
              break;
            case 'ESCAPE':
              NativeInputHelper.keyEvent(keyCode: 0x1B, isUp: false);
              NativeInputHelper.keyEvent(keyCode: 0x1B, isUp: true);
              break;
            case 'SPACE':
              NativeInputHelper.keyEvent(keyCode: 0x20, isUp: false);
              NativeInputHelper.keyEvent(keyCode: 0x20, isUp: true);
              break;
          }
        } else if (text != null && text.isNotEmpty) {
          for (final rune in text.runes) {
            NativeInputHelper.typeChar(String.fromCharCode(rune));
          }
        }
        break;
    }
  }

  // ── Sender Methods (Invoked by Mobile Trackpad UI) ──────────────────────────

  Future<void> sendMouseMove({
    required String targetAddress,
    required double dx,
    required double dy,
  }) async {
    await _sendUdpPacket(targetAddress, {
      'type': 'MOUSE_MOVE',
      'dx': dx,
      'dy': dy,
    });
  }

  Future<void> sendMouseClick({
    required String targetAddress,
    required String button,
  }) async {
    await _sendUdpPacket(targetAddress, {
      'type': 'MOUSE_CLICK',
      'button': button,
    });
  }

  Future<void> sendMouseScroll({
    required String targetAddress,
    required double dy,
  }) async {
    await _sendUdpPacket(targetAddress, {
      'type': 'MOUSE_SCROLL',
      'dy': dy,
    });
  }

  Future<void> sendKeyInput({
    required String targetAddress,
    String? text,
    String? key,
  }) async {
    await _sendUdpPacket(targetAddress, {
      'type': 'KEY_INPUT',
      if (text != null) 'text': text,
      if (key != null) 'key': key,
    });
  }

  RawDatagramSocket? _senderSocket;

  Future<void> _sendUdpPacket(String targetAddress, Map<String, dynamic> payload) async {
    if (kIsWeb) return;
    try {
      _senderSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final jsonBytes = utf8.encode(jsonEncode(payload));
      _senderSocket!.send(jsonBytes, InternetAddress(targetAddress), kRemoteInputUdpPort);
    } catch (e) {
      logger.warning('RemoteInput', 'Failed to send input packet: $e');
    }
  }

  void dispose() {
    _udpReceiver?.close();
    _senderSocket?.close();
    _initialized = false;
  }
}
