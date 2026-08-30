// lib/application/connection_service.dart
// Manages live connections to trusted peers.
// Sends periodic heartbeats; marks peers online/offline based on response.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/logging/app_logger.dart';
import '../data/security/device_identity.dart';
import '../data/transport/protocol.dart';
import '../data/transport/tcp_client.dart';
import '../domain/entities/device.dart';

const _kHeartbeatInterval = Duration(seconds: 15);
const _kHeartbeatTimeout = Duration(seconds: 10);

class ConnectedPeer {
  ConnectedPeer({
    required this.device,
    required this.connection,
  });

  final Device device;
  PeerConnection connection;
  Timer? heartbeatTimer;
  DateTime lastSeen = DateTime.now();
  bool isOnline = true;
}

class ConnectionService {
  ConnectionService._();
  static final ConnectionService instance = ConnectionService._();

  final _connections = <String, ConnectedPeer>{}; // keyed by deviceId
  final _statusController =
      StreamController<Map<String, bool>>.broadcast();

  /// Stream of deviceId → isOnline updates.
  Stream<Map<String, bool>> get statusUpdates => _statusController.stream;

  /// Establish a connection to a trusted device. Used after pairing.
  Future<bool> connect(Device device) async {
    if (_connections.containsKey(device.deviceId)) return true;
    if (device.address == null || device.port == null) {
      logger.warning('ConnectionService', 'No address for ${device.displayName}');
      return false;
    }

    try {
      final conn = PeerConnection(
        deviceId: device.deviceId,
        address: device.address!,
        port: device.port!,
      );
      await conn.connect();

      final peer = ConnectedPeer(device: device, connection: conn);
      _connections[device.deviceId] = peer;

      // Send hello
      await _sendHello(conn);

      // Listen for messages
      conn.messages.listen(
        (msg) => _handleMessage(msg, peer),
        onError: (_) => _markOffline(device.deviceId),
        onDone: () => _markOffline(device.deviceId),
      );

      // Start heartbeat
      peer.heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) {
        _sendHeartbeat(peer);
      });

      _emit();
      logger.info('ConnectionService', 'Connected to ${device.displayName}');
      return true;
    } catch (e) {
      logger.error('ConnectionService', 'Connect failed for ${device.displayName}', e);
      return false;
    }
  }

  void _handleMessage(ProtocolMessage msg, ConnectedPeer peer) {
    peer.lastSeen = DateTime.now();
    if (!peer.isOnline) {
      peer.isOnline = true;
      _emit();
    }
    // Heartbeat responses just update lastSeen — no extra action needed.
  }

  Future<void> _sendHello(PeerConnection conn) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    final msg = ProtocolMessage(
      version: kProtocolVersion,
      type: msgHello,
      messageId: const Uuid().v4(),
      sourceDeviceId: identity.deviceId,
      timestamp: DateTime.now(),
      payload: helloPayload(
        displayName: identity.deviceId,
        platform: kIsWeb
            ? 'web'
            : (Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : Platform.isLinux
                        ? 'linux'
                        : 'unknown'),
        capabilities: ['clipboard', 'file', 'link'],
        ecosystemHint: '',
      ),
    );
    await conn.send(msg);
  }

  Future<void> _sendHeartbeat(ConnectedPeer peer) async {
    final identity = await DeviceIdentityService.instance.getOrCreate();
    try {
      final msg = ProtocolMessage(
        version: kProtocolVersion,
        type: msgHeartbeat,
        messageId: const Uuid().v4(),
        sourceDeviceId: identity.deviceId,
        timestamp: DateTime.now(),
        payload: const {},
      );
      await peer.connection.send(msg);

      // If no response within timeout, mark offline
      final now = DateTime.now();
      if (now.difference(peer.lastSeen) > _kHeartbeatTimeout * 2) {
        _markOffline(peer.device.deviceId);
      }
    } catch (_) {
      _markOffline(peer.device.deviceId);
    }
  }

  void _markOffline(String deviceId) {
    final peer = _connections[deviceId];
    if (peer != null && peer.isOnline) {
      peer.isOnline = false;
      _emit();
      logger.info('ConnectionService', '${peer.device.displayName} went offline');
    }
  }

  void _emit() {
    _statusController.add({
      for (final e in _connections.entries) e.key: e.value.isOnline,
    });
  }

  Future<void> disconnect(String deviceId) async {
    final peer = _connections.remove(deviceId);
    if (peer != null) {
      peer.heartbeatTimer?.cancel();
      await peer.connection.disconnect();
    }
    _emit();
  }

  PeerConnection? getConnection(String deviceId) =>
      _connections[deviceId]?.connection;

  bool isOnline(String deviceId) =>
      _connections[deviceId]?.isOnline ?? false;

  Future<void> dispose() async {
    for (final peer in _connections.values) {
      peer.heartbeatTimer?.cancel();
      await peer.connection.disconnect();
    }
    _connections.clear();
    await _statusController.close();
  }
}
