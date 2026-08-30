import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nsd/nsd.dart' as nsd_pkg;
import '../../core/logging/app_logger.dart';
import '../../data/transport/protocol.dart';

const _kServiceType = '_localeco._tcp';

/// A peer discovered via mDNS — not yet trusted.
class DiscoveredPeer {
  const DiscoveredPeer({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.address,
    required this.port,
    required this.protocolVersion,
    required this.ecosystemHint,
    required this.capabilities,
  });

  final String deviceId;
  final String displayName;
  final String platform;
  final String address;
  final int port;
  final int protocolVersion;
  final String ecosystemHint;
  final List<String> capabilities;
}

class MdnsService {
  MdnsService({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.ecosystemId,
    required this.capabilities,
  });

  final String deviceId;
  final String displayName;
  final String platform;
  final String ecosystemId;
  final List<String> capabilities;

  nsd_pkg.Registration? _registration;
  nsd_pkg.Discovery? _discovery;

  final _peersController =
      StreamController<List<DiscoveredPeer>>.broadcast();
  final _peers = <String, DiscoveredPeer>{}; // keyed by deviceId

  Stream<List<DiscoveredPeer>> get peers => _peersController.stream;
  List<DiscoveredPeer> get currentPeers => _peers.values.toList();

  // ── Advertise ─────────────────────────────────────────────────────────────

  Future<void> startAdvertising(int port) async {
    if (Platform.isLinux || Platform.isWindows) return;
    try {
      final txt = <String, Uint8List?>{
        'did': _encode(deviceId),
        'dname': _encode(displayName),
        'plat': _encode(platform),
        'pver': _encode(kProtocolVersion.toString()),
        'eco': _encode(ecosystemId),
        'caps': _encode(capabilities.join(',')),
      };

      _registration = await nsd_pkg.register(nsd_pkg.Service(
        name: displayName,
        type: _kServiceType,
        port: port,
        txt: txt,
      ));
      logger.info('MdnsService', 'Advertising as "$displayName" on port $port');
    } catch (e) {
      logger.error('MdnsService', 'Failed to start advertising', e);
    }
  }

  Future<void> stopAdvertising() async {
    if (_registration != null) {
      await nsd_pkg.unregister(_registration!);
      _registration = null;
      logger.info('MdnsService', 'Stopped advertising');
    }
  }

  // ── Discover ──────────────────────────────────────────────────────────────

  Future<void> startDiscovery() async {
    if (Platform.isLinux || Platform.isWindows) return;
    try {
      _discovery = await nsd_pkg.startDiscovery(
        _kServiceType,
        autoResolve: true,
        ipLookupType: nsd_pkg.IpLookupType.v4,
      );

      _discovery!.addServiceListener((service, status) {
        if (status == nsd_pkg.ServiceStatus.found) {
          _handleFound(service);
        } else if (status == nsd_pkg.ServiceStatus.lost) {
          _handleLost(service);
        }
      });
      logger.info('MdnsService', 'Discovery started');
    } catch (e) {
      logger.error('MdnsService', 'Failed to start discovery', e);
    }
  }

  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await nsd_pkg.stopDiscovery(_discovery!);
      _discovery = null;
      logger.info('MdnsService', 'Discovery stopped');
    }
  }

  void _handleFound(nsd_pkg.Service service) {
    try {
      final txt = service.txt;
      if (txt == null) return;

      final peerId = _decode(txt['did']);
      final peerName = _decode(txt['dname']);
      final peerPlatform = _decode(txt['plat']) ?? 'unknown';
      final peerVersion = int.tryParse(_decode(txt['pver']) ?? '0') ?? 0;
      final peerEco = _decode(txt['eco']) ?? '';
      final peerCaps = (_decode(txt['caps']) ?? '').split(',');

      if (peerId == null || peerId.isEmpty) return;
      if (peerId == deviceId) return; // ignore self

      final addresses = service.addresses;
      if (addresses == null || addresses.isEmpty) return;
      final address = addresses.first.address;
      final port = service.port ?? kDefaultPort;

      final peer = DiscoveredPeer(
        deviceId: peerId,
        displayName: peerName ?? 'Unknown Device',
        platform: peerPlatform,
        address: address,
        port: port,
        protocolVersion: peerVersion,
        ecosystemHint: peerEco,
        capabilities: peerCaps,
      );

      _peers[peerId] = peer;
      _peersController.add(_peers.values.toList());
      logger.info('MdnsService', 'Found peer: ${peer.displayName} @ $address:$port');
    } catch (e) {
      logger.warning('MdnsService', 'Error parsing discovered service: $e');
    }
  }

  void _handleLost(nsd_pkg.Service service) {
    try {
      final txt = service.txt;
      if (txt == null) return;
      final peerId = _decode(txt['did']);
      if (peerId == null) return;

      _peers.remove(peerId);
      _peersController.add(_peers.values.toList());
      logger.info('MdnsService', 'Lost peer: $peerId');
    } catch (e) {
      logger.warning('MdnsService', 'Error handling lost service: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Uint8List? _encode(String? value) =>
      value != null ? Uint8List.fromList(utf8.encode(value)) : null;

  static String? _decode(Uint8List? bytes) =>
      bytes != null ? utf8.decode(bytes, allowMalformed: true) : null;

  Future<void> dispose() async {
    await stopDiscovery();
    await stopAdvertising();
    await _peersController.close();
  }
}
