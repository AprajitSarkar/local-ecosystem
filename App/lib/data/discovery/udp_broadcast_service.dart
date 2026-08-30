// lib/data/discovery/udp_broadcast_service.dart
// Resilient dual-route UDP discovery engine — Subnet Broadcast + Direct Unicast.
// Auto-registers peers from any received packet to guarantee zero discovery delays.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../application/clipboard_sync_service.dart';
import '../../application/media_control_service.dart';
import '../../application/notification_mirror_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/logging/crash_reporting_service.dart';
import '../transport/protocol.dart';
import 'mdns_service.dart';

const int kUdpDiscoveryPort = 42421;

class UdpBroadcastService {
  UdpBroadcastService({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.ecosystemId,
    required this.tcpPort,
    required this.capabilities,
  });

  final String deviceId;
  final String displayName;
  final String platform;
  final String ecosystemId;
  final int tcpPort;
  final List<String> capabilities;

  static final Set<String> knownPeerIps = {};
  final Set<String> _localAddresses = {'127.0.0.1'};

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _pruneTimer;
  final Map<String, DiscoveredPeer> _peers = {};
  final Map<String, DateTime> _lastSeen = {};
  final StreamController<List<DiscoveredPeer>> _peersController =
      StreamController<List<DiscoveredPeer>>.broadcast();

  Stream<List<DiscoveredPeer>> get peers => _peersController.stream;
  List<DiscoveredPeer> get currentPeers => _peers.values.toList();

  Future<void> start() async {
    try {
      if (!kIsWeb) {
        try {
          final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
          for (final iface in ifaces) {
            for (final addr in iface.addresses) {
              _localAddresses.add(addr.address);
            }
          }
        } catch (_) {}
      }

      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kUdpDiscoveryPort,
        reuseAddress: true,
        reusePort: !Platform.isWindows,
      );
      _socket!.broadcastEnabled = true;
      _socket!.listen(_handleSocketEvents);
      logger.info('UdpDiscovery', 'Listening on UDP port $kUdpDiscoveryPort');

      // Immediate announcement + ping on start
      await sendAnnouncement();
      await sendPing();

      // Periodic broadcast every 4 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        sendAnnouncement();
      });

      // Prune inactive peers (25 seconds timeout)
      _pruneTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _pruneStalePeers();
      });
    } catch (e) {
      logger.error('UdpDiscovery', 'Failed to bind UDP discovery socket', e);
    }
  }

  void _handleSocketEvents(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      while (true) {
        final datagram = _socket?.receive();
        if (datagram == null) break;

        final senderAddress = datagram.address.address;
        if (senderAddress != '127.0.0.1') {
          knownPeerIps.add(senderAddress);
        }

        try {
          final text = utf8.decode(datagram.data);
          final map = jsonDecode(text) as Map<String, dynamic>;
          final type = map['type']?.toString();

          if (type == 'ANNOUNCE') {
            final peerId = map['deviceId']?.toString();
            if (peerId == null || peerId.isEmpty || peerId == deviceId) continue;

            final port = (map['tcpPort'] as num?)?.toInt() ?? 51413;
            final peerName = map['displayName']?.toString() ?? 'Device';
            final peerPlatform = map['platform']?.toString() ?? 'unknown';
            final peerEco = map['ecosystemId']?.toString() ?? map['ecosystemName']?.toString() ?? '';
            final peerCaps = (map['caps'] as List?)?.map((c) => c.toString()).toList() ??
                ['clipboard', 'file', 'link'];

            _autoRegisterPeer(
              peerId: peerId,
              senderName: peerName,
              senderAddress: senderAddress,
              port: port,
              platform: peerPlatform,
              ecosystemHint: peerEco,
              capabilities: peerCaps,
            );
          } else if (type == 'PING') {
            final fromId = map['deviceId']?.toString();
            if (fromId != deviceId) {
              sendAnnouncement(targetAddress: datagram.address);
            }
          } else if (type == 'CLIPBOARD_SYNC') {
            final text = map['text']?.toString();
            final senderName = map['deviceName']?.toString() ?? 'Device';
            final senderId = map['deviceId']?.toString() ?? '';
            final senderEco = map['ecosystemId']?.toString() ?? '';
            if (senderId.isNotEmpty && senderId != deviceId) {
              _autoRegisterPeer(
                peerId: senderId,
                senderName: senderName,
                senderAddress: senderAddress,
                port: 51413,
                ecosystemHint: senderEco,
              );
              if (text != null && text.isNotEmpty) {
                ClipboardSyncService.instance.handleIncomingClipboard(
                  senderDeviceName: senderName,
                  senderDeviceId: senderId,
                  text: text,
                );
              }
            }
          } else if (type == 'IMAGE_CLIPBOARD_SYNC') {
            final senderName = map['deviceName']?.toString() ?? 'Device';
            final senderId = map['deviceId']?.toString() ?? '';
            final senderEco = map['ecosystemId']?.toString() ?? '';
            final dataBase64 = map['data']?.toString();
            if (senderId.isNotEmpty && senderId != deviceId) {
              _autoRegisterPeer(
                peerId: senderId,
                senderName: senderName,
                senderAddress: senderAddress,
                port: 51413,
                ecosystemHint: senderEco,
              );
              if (dataBase64 != null && dataBase64.isNotEmpty) {
                final imageBytes = base64Decode(dataBase64);
                ClipboardSyncService.instance.handleIncomingImageClipboard(
                  senderDeviceName: senderName,
                  senderDeviceId: senderId,
                  imageBytes: imageBytes,
                );
              }
            }
          } else if (type == 'LINK_SHARE') {
            final url = map['url']?.toString();
            final senderName = map['deviceName']?.toString() ?? 'Device';
            final senderId = map['deviceId']?.toString() ?? '';
            final senderEco = map['ecosystemId']?.toString() ?? '';
            // STRICT FILTER: Do not open link on the sending device
            if (senderId.isNotEmpty && senderId != deviceId && senderName != displayName) {
              _autoRegisterPeer(
                peerId: senderId,
                senderName: senderName,
                senderAddress: senderAddress,
                port: 51413,
                ecosystemHint: senderEco,
              );
              if (url != null && url.isNotEmpty) {
                ClipboardSyncService.instance.handleIncomingLink(
                  senderDeviceName: senderName,
                  url: url,
                );
              }
            }
          } else if (type == 'NOTIFICATION_MIRROR') {
            final senderName = map['deviceName']?.toString() ?? 'Device';
            final senderId = map['deviceId']?.toString() ?? '';
            final appName = map['appName']?.toString() ?? 'App';
            final title = map['title']?.toString() ?? '';
            final text = map['text']?.toString() ?? '';
            final otpCode = map['otpCode']?.toString();
            if (senderId.isNotEmpty && senderId != deviceId) {
              NotificationMirrorService.instance.handleIncomingNotification(
                senderDeviceName: senderName,
                appName: appName,
                title: title,
                text: text,
                otpCode: otpCode,
              );
            }
          } else if (type == 'MEDIA_STATE') {
            final senderId = map['deviceId']?.toString() ?? '';
            if (senderId.isNotEmpty && senderId != deviceId) {
              MediaControlService.instance.handleIncomingMediaState(map);
            }
          } else if (type == 'MEDIA_COMMAND') {
            final action = map['action']?.toString() ?? '';
            if (action.isNotEmpty) {
              MediaControlService.instance.handleIncomingMediaCommand(action);
            }
          } else if (type == 'CRASH_LOG_SYNC') {
            final entry = CrashLogEntry.fromJson(map);
            CrashReportingService.instance.recordRemoteCrash(entry);
          }
        } catch (e) {
          logger.warning('UdpDiscovery', 'Error parsing UDP datagram: $e');
        }
      }
    }
  }

  void _autoRegisterPeer({
    required String peerId,
    required String senderName,
    required String senderAddress,
    required int port,
    String platform = 'unknown',
    String ecosystemHint = '',
    List<String> capabilities = const ['clipboard', 'file', 'link'],
  }) {
    if (peerId.isEmpty ||
        peerId == deviceId ||
        senderAddress == '127.0.0.1' ||
        _localAddresses.contains(senderAddress) ||
        (senderName.isNotEmpty && senderName == displayName)) {
      return;
    }
    final existing = _peers[peerId];
    if (existing == null || existing.address != senderAddress) {
      final peer = DiscoveredPeer(
        deviceId: peerId,
        displayName: senderName.isNotEmpty ? senderName : 'Device ($senderAddress)',
        platform: platform,
        address: senderAddress,
        port: port,
        protocolVersion: 1,
        ecosystemHint: ecosystemHint.isNotEmpty ? ecosystemHint : ecosystemId,
        capabilities: capabilities,
      );
      _peers[peerId] = peer;
      _lastSeen[peerId] = DateTime.now();
      _peersController.add(_peers.values.toList());
      logger.info('UdpDiscovery', 'Found/Registered peer: ${peer.displayName} @ $senderAddress:$port (Eco: ${peer.ecosystemHint})');

      if (Platform.isAndroid) {
        try {
          const MethodChannel('com.localecosystem/clipboard').invokeMethod('recordPeerIp', {
            'ip': senderAddress,
            'name': peer.displayName,
          });
        } catch (_) {}
      }
    } else {
      _lastSeen[peerId] = DateTime.now();
    }
  }

  Future<void> sendAnnouncement({InternetAddress? targetAddress}) async {
    if (_socket == null) return;

    final payload = jsonEncode({
      'type': 'ANNOUNCE',
      'deviceId': deviceId,
      'displayName': displayName,
      'platform': platform,
      'pver': kProtocolVersion,
      'ecosystemId': ecosystemId,
      'tcpPort': tcpPort,
      'caps': capabilities,
    });
    final bytes = utf8.encode(payload);

    if (targetAddress != null) {
      try {
        _socket?.send(bytes, targetAddress, kUdpDiscoveryPort);
      } catch (_) {}
      return;
    }

    // Direct unicast to all known peer IP addresses
    for (final peerIp in knownPeerIps) {
      try {
        _socket?.send(bytes, InternetAddress(peerIp), kUdpDiscoveryPort);
      } catch (_) {}
    }

    // Global broadcast
    try {
      _socket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        kUdpDiscoveryPort,
      );
    } catch (_) {}

    // Subnet interfaces broadcast
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
            _socket?.send(
              bytes,
              InternetAddress(broadcastIp),
              kUdpDiscoveryPort,
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> sendPing() async {
    if (_socket == null) return;
    final payload = jsonEncode({
      'type': 'PING',
      'deviceId': deviceId,
    });
    final bytes = utf8.encode(payload);

    for (final peerIp in knownPeerIps) {
      try {
        _socket?.send(bytes, InternetAddress(peerIp), kUdpDiscoveryPort);
      } catch (_) {}
    }

    try {
      _socket?.send(bytes, InternetAddress('255.255.255.255'), kUdpDiscoveryPort);
    } catch (_) {}
  }

  void _pruneStalePeers() {
    final now = DateTime.now();
    final stale = <String>[];
    _lastSeen.forEach((id, last) {
      if (now.difference(last).inSeconds > 25) {
        stale.add(id);
      }
    });

    if (stale.isNotEmpty) {
      for (final id in stale) {
        _peers.remove(id);
        _lastSeen.remove(id);
      }
      _peersController.add(_peers.values.toList());
    }
  }

  Future<void> stop() async {
    _broadcastTimer?.cancel();
    _pruneTimer?.cancel();
    _socket?.close();
    _socket = null;
    _peers.clear();
    _lastSeen.clear();
    await _peersController.close();
  }
}
