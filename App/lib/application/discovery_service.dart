// lib/application/discovery_service.dart
// Application-layer service that wires UDP Subnet Broadcast + mDNS + TCP server together.
// Provides a unified, resilient, zero-lag stream of online/offline peers to the UI.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../app/providers.dart';
import '../core/logging/app_logger.dart';
import '../core/web/web_pwa_service.dart';
import '../data/discovery/mdns_service.dart';
import '../data/discovery/udp_broadcast_service.dart';
import '../data/security/device_identity.dart';
import '../data/transport/protocol.dart';
import '../data/transport/tcp_server.dart';
import '../domain/entities/device.dart';
import 'clipboard_sync_service.dart';
import 'settings_service.dart';
import 'web_portal_server.dart';

/// Wraps a discovered + possibly online peer for the UI.
class PeerState {
  const PeerState({
    required this.peer,
    this.isOnline = false,
    this.isTrusted = false,
    this.socket,
  });

  final DiscoveredPeer peer;
  final bool isOnline;
  final bool isTrusted;
  final Socket? socket;

  PeerState copyWith({bool? isOnline, bool? isTrusted, Socket? socket}) =>
      PeerState(
        peer: peer,
        isOnline: isOnline ?? this.isOnline,
        isTrusted: isTrusted ?? this.isTrusted,
        socket: socket ?? this.socket,
      );
}

class DiscoveryService extends Notifier<List<PeerState>> {
  MdnsService? _mdns;
  UdpBroadcastService? _udp;
  LanServer? _server;
  StreamSubscription<List<DiscoveredPeer>>? _mdnsSub;
  StreamSubscription<List<DiscoveredPeer>>? _udpSub;
  Timer? _webPollTimer;
  Timer? _subnetScanTimer;
  final Map<String, DiscoveredPeer> _allDiscovered = {};
  bool _running = false;
  bool _isScanningSubnet = false;

  @override
  List<PeerState> build() => [];

  Future<void> start() async {
    if (_running) return;
    _running = true;

    if (kIsWeb) {
      _startWebPolling();
      return;
    }

    final identity = await DeviceIdentityService.instance.getOrCreate();
    final settings = SettingsService.instance;

    // Connect Web Portal registrations to DiscoveryService
    WebPortalServer.instance.onWebPeerDiscovered = registerWebPeer;

    // Start TCP server
    _server = LanServer();
    _server!.onMessage = (msg, socket) {
      if (msg.type == msgPairingRequest) {
        ref.read(pairingServiceProvider).handleIncomingRequest(msg, socket);
      } else if (msg.type == msgTransferOffer ||
          msg.type == msgTransferChunk ||
          msg.type == msgTransferComplete) {
        ref.read(transferServiceProvider).handleIncomingMessage(msg, socket);
      } else if (msg.type == 'image_clipboard') {
        try {
          final payload = msg.payload;
          final b64 = payload['data'] as String?;
          final senderName = payload['deviceName'] as String? ?? 'Device';
          if (b64 != null && b64.isNotEmpty) {
            final bytes = base64Decode(b64);
            ClipboardSyncService.instance.handleIncomingImageClipboard(
              senderDeviceName: senderName,
              senderDeviceId: msg.sourceDeviceId,
              imageBytes: bytes,
            );
          }
        } catch (e) {
          logger.warning('DiscoveryService', 'Error handling image_clipboard TCP: $e');
        }
      } else if (msg.type == 'text_clipboard') {
        try {
          final payload = msg.payload;
          final text = payload['text'] as String?;
          final senderName = payload['deviceName'] as String? ?? 'Device';
          if (text != null && text.isNotEmpty) {
            ClipboardSyncService.instance.handleIncomingClipboard(
              senderDeviceName: senderName,
              senderDeviceId: msg.sourceDeviceId,
              text: text,
            );
          }
        } catch (e) {
          logger.warning('DiscoveryService', 'Error handling text_clipboard TCP: $e');
        }
      } else if (msg.type == 'link_share') {
        try {
          final payload = msg.payload;
          final url = payload['url'] as String?;
          final senderName = payload['deviceName'] as String? ?? 'Device';
          if (url != null && url.isNotEmpty) {
            ClipboardSyncService.instance.handleIncomingLink(
              senderDeviceName: senderName,
              url: url,
            );
          }
        } catch (e) {
          logger.warning('DiscoveryService', 'Error handling link_share TCP: $e');
        }
      }
    };
    await _server!.start();
    final tcpPort = _server!.port;
    logger.info('DiscoveryService', 'TCP server on port $tcpPort');

    // 1. Start UDP Broadcast discovery
    _udp = UdpBroadcastService(
      deviceId: identity.deviceId,
      displayName: settings.deviceName,
      platform: _platformString(),
      ecosystemId: settings.ecosystemName,
      tcpPort: tcpPort,
      capabilities: ['clipboard', 'file', 'link'],
    );
    await _udp!.start();
    _udpSub = _udp!.peers.listen(_onDiscoveredPeers);

    // 2. Start mDNS advertising + discovery (Bonjour/ZeroConf)
    _mdns = MdnsService(
      deviceId: identity.deviceId,
      displayName: settings.deviceName,
      platform: _platformString(),
      ecosystemId: settings.ecosystemName,
      capabilities: ['clipboard', 'file', 'link'],
    );
    await _mdns!.startAdvertising(tcpPort);
    await _mdns!.startDiscovery();
    _mdnsSub = _mdns!.peers.listen(_onDiscoveredPeers);

    // 3. Proactive LAN Subnet Probing (bypasses router broadcast blocks)
    triggerSubnetScan();
    _subnetScanTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      triggerSubnetScan();
    });

    logger.info('DiscoveryService', 'Triple Discovery (UDP + mDNS + Active Subnet Probe) active');
  }

  void broadcastNow() {
    _udp?.sendAnnouncement();
    triggerSubnetScan();
  }

  void broadcastPing() {
    _udp?.sendPing();
    triggerSubnetScan();
  }

  /// Proactively scans all local network subnets for active peers over HTTP/TCP
  Future<void> triggerSubnetScan() async {
    if (_isScanningSubnet || kIsWeb) return;
    _isScanningSubnet = true;

    try {
      final subnetsToScan = <String>{
        '192.168.1.',
        '192.168.0.',
        '192.168.29.',
        '192.168.43.',
        '172.20.10.',
      };

      // Dynamically discover actual network interface subnets
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4 && !addr.address.startsWith('127.')) {
              final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
              subnetsToScan.add(prefix);
            }
          }
        }
      } catch (_) {}

      for (final subnet in subnetsToScan) {
        if (!_running) break;
        // Batch scan in chunks of 30 concurrent probes
        for (int i = 1; i <= 254; i += 30) {
          if (!_running) break;
          final futures = <Future>[];
          for (int j = i; j < i + 30 && j <= 254; j++) {
            final ip = '$subnet$j';
            futures.add(_probePeerAtIp(ip));
          }
          await Future.wait(futures);
        }
      }
    } catch (e) {
      logger.warning('DiscoveryService', 'Subnet scan error: $e');
    } finally {
      _isScanningSubnet = false;
    }
  }

  Future<void> _probePeerAtIp(String ip) async {
    final myDeviceId = DeviceIdentityService.instance.currentDeviceId;
    final myName = SettingsService.instance.deviceName;

    // Check port 8080 (Web Portal Server & status API)
    final ports = [8080, 8081, 8082];
    for (final port in ports) {
      try {
        final uri = Uri.parse('http://$ip:$port/api/status');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 900));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final peerId = data['deviceId'] as String? ?? data['ecosystemId'] as String? ?? 'host-$ip';
          final hostName = data['hostDeviceName'] as String? ?? 'Device';
          final ecoName = data['ecosystemName'] as String? ?? '$hostName’s Ecosystem';
          final rawPlatform = data['platform'] as String?;
          final platform = DevicePlatform.fromString(rawPlatform, hostName).name;
          final portalPort = (data['portalPort'] as num?)?.toInt() ?? port;

          if (peerId != myDeviceId && (myName.isEmpty || hostName != myName)) {
            final peer = DiscoveredPeer(
              deviceId: peerId,
              displayName: hostName,
              platform: platform,
              address: ip,
              port: portalPort,
              protocolVersion: 1,
              ecosystemHint: ecoName,
              capabilities: ['clipboard', 'file', 'link'],
            );
            registerDiscoveredPeer(peer);
          }
          return;
        }
      } catch (_) {}
    }
  }

  void registerDiscoveredPeer(DiscoveredPeer peer) {
    _onDiscoveredPeers([peer]);
  }

  Future<void> stop() async {
    _running = false;
    _subnetScanTimer?.cancel();
    await _mdnsSub?.cancel();
    await _udpSub?.cancel();
    await _mdns?.dispose();
    await _udp?.stop();
    await _server?.stop();
    _allDiscovered.clear();
    state = [];
  }

  void _onDiscoveredPeers(List<DiscoveredPeer> peers) {
    final myDeviceId = DeviceIdentityService.instance.currentDeviceId;
    final myName = SettingsService.instance.deviceName;

    for (final p in peers) {
      if (p.deviceId == myDeviceId || (myName.isNotEmpty && p.displayName == myName)) {
        continue;
      }
      _allDiscovered[p.deviceId] = p;
    }

    // Auto-heal trusted device records in SQLite database if platform was previously unknown
    try {
      final deviceDao = ref.read(deviceDaoProvider);
      for (final p in peers) {
        final plat = DevicePlatform.fromString(p.platform, p.displayName).name;
        deviceDao.getDevice(p.deviceId).then((existing) {
          if (existing != null && (existing.platform == 'unknown' || existing.platform.isEmpty || existing.platform != plat)) {
            deviceDao.upsertDevice(existing.toCompanion(true).copyWith(
              platform: Value(plat),
            ));
          }
        });
      }
    } catch (_) {}

    final currentById = {for (final p in state) p.peer.deviceId: p};
    final newState = <PeerState>[];

    for (final peer in _allDiscovered.values) {
      if (peer.deviceId == myDeviceId || (myName.isNotEmpty && peer.displayName == myName)) {
        continue;
      }
      final existing = currentById[peer.deviceId];
      newState.add(existing?.copyWith(isOnline: true) ??
          PeerState(peer: peer, isOnline: true));
    }

    state = newState;

    if (newState.isNotEmpty) {
      ClipboardSyncService.instance
          .updatePersistentNotification(newState.first.peer.displayName);
    } else {
      ClipboardSyncService.instance.updatePersistentNotification();
    }
  }

  void registerWebPeer(DiscoveredPeer peer) {
    _onDiscoveredPeers([peer]);
  }

  void _startWebPolling() {
    _webPollTimer?.cancel();
    _fetchWebPeers();
    _webPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchWebPeers();
    });
  }

  Future<void> _fetchWebPeers() async {
    final hostUrl = WebPwaService.instance.hostUrl.isNotEmpty
        ? WebPwaService.instance.hostUrl
        : (kIsWeb ? Uri.base.origin : 'http://127.0.0.1:8080');

    try {
      String ecoName = "Aprajit's Ecosystem";
      String hostName = "Host Device";

      try {
        final statusRes = await http.get(Uri.parse('$hostUrl/api/status')).timeout(const Duration(seconds: 2));
        if (statusRes.statusCode == 200) {
          final sData = jsonDecode(statusRes.body) as Map<String, dynamic>;
          ecoName = sData['ecosystemName'] as String? ?? "Aprajit's Ecosystem";
          hostName = sData['hostDeviceName'] as String? ?? "Host Device";
        }
      } catch (_) {}

      final res = await http.get(Uri.parse('$hostUrl/api/peers')).timeout(const Duration(seconds: 2));
      final peers = <DiscoveredPeer>[];

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final peersJson = (data['peers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final item in peersJson) {
          final devId = item['deviceId'] as String? ?? '';
          final name = item['displayName'] as String? ?? 'Device';
          final platform = item['platform'] as String? ?? 'unknown';
          final addr = item['address'] as String? ?? '';
          final port = (item['port'] as num?)?.toInt() ?? 8080;

          peers.add(DiscoveredPeer(
            deviceId: devId,
            displayName: name,
            platform: platform,
            address: addr,
            port: port,
            protocolVersion: 1,
            ecosystemHint: ecoName,
            capabilities: ['clipboard', 'file', 'link'],
          ));
        }
      }

      _onDiscoveredPeers(peers);
    } catch (e) {
      logger.warning('DiscoveryService', 'Error in _fetchWebPeers: $e');
    }
  }

  LanServer? get server => _server;
  MdnsService? get mdns => _mdns;
  UdpBroadcastService? get udp => _udp;

  static String _platformString() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }
}

final discoveryServiceProvider =
    NotifierProvider<DiscoveryService, List<PeerState>>(
  DiscoveryService.new,
);
