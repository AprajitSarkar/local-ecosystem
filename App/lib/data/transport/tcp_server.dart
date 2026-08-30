// lib/data/transport/tcp_server.dart
// Listens for inbound LAN connections from trusted peers with stream-safe framing.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/logging/app_logger.dart';
import 'protocol.dart';

typedef MessageHandler = void Function(ProtocolMessage msg, Socket socket);

class LanServer {
  ServerSocket? _server;
  final List<Socket> _clients = [];
  MessageHandler? onMessage;

  int get port => _server?.port ?? kDefaultPort;

  Future<void> start({int port = kDefaultPort}) async {
    if (_server != null) {
      try {
        await _server?.close();
      } catch (_) {}
      _server = null;
    }
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    logger.info('LanServer', 'Listening on port ${_server!.port}');
    _server!.listen(_handleClient, onError: (e) {
      logger.error('LanServer', 'Server error', e);
    });
  }

  void _handleClient(Socket socket) {
    logger.info('LanServer', 'Inbound connection from ${socket.remoteAddress.address}');
    _clients.add(socket);

    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (String line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return;
        try {
          final msg = ProtocolMessage.decode(trimmed);
          if (msg.isValid) {
            onMessage?.call(msg, socket);
          } else {
            logger.warning('LanServer', 'Invalid protocol message received');
          }
        } catch (e) {
          logger.warning('LanServer', 'Failed to decode message: $e');
        }
      },
      onError: (e) {
        logger.warning('LanServer', 'Socket error from ${socket.remoteAddress.address}: $e');
        _clients.remove(socket);
        socket.destroy();
      },
      onDone: () {
        logger.info('LanServer', 'Client disconnected: ${socket.remoteAddress.address}');
        _clients.remove(socket);
      },
      cancelOnError: true,
    );
  }

  Future<void> stop() async {
    for (final c in _clients) {
      c.destroy();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
  }
}
