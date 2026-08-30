// lib/data/transport/tcp_client.dart
// Establishes outbound LAN connections to peer devices with stream-safe framing.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../core/logging/app_logger.dart';
import 'protocol.dart';

class PeerConnection {
  PeerConnection({
    required this.deviceId,
    required this.address,
    required this.port,
  });

  final String deviceId;
  final String address;
  final int port;

  Socket? _socket;
  final StreamController<ProtocolMessage> _messageController =
      StreamController.broadcast();
  bool _connected = false;

  Stream<ProtocolMessage> get messages => _messageController.stream;
  bool get isConnected => _connected;

  Future<void> connect({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      _socket = await Socket.connect(
        address,
        port,
        timeout: timeout,
      );
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      _connected = true;
      logger.info('PeerConnection', 'Connected to $address:$port ($deviceId)');

      _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return;
          try {
            final msg = ProtocolMessage.decode(trimmed);
            if (msg.isValid && !_messageController.isClosed) {
              _messageController.add(msg);
            }
          } catch (e) {
            logger.warning('PeerConnection', 'Decode error from $deviceId: $e');
          }
        },
        onError: (e) {
          logger.warning('PeerConnection', 'Socket error with $deviceId: $e');
          _connected = false;
        },
        onDone: () {
          logger.info('PeerConnection', 'Peer connection closed: $deviceId');
          _connected = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      _connected = false;
      logger.error('PeerConnection', 'Failed to connect to $address:$port', e);
      rethrow;
    }
  }

  Future<void> send(ProtocolMessage msg) async {
    if (_socket == null || !_connected) {
      throw StateError('Not connected to $deviceId');
    }
    try {
      _socket!.write('${msg.encode()}\n');
      await _socket!.flush();
    } catch (e) {
      _connected = false;
      logger.error('PeerConnection', 'Send failed to $deviceId', e);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _connected = false;
    try {
      await _socket?.flush();
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    if (!_messageController.isClosed) {
      await _messageController.close();
    }
  }
}
