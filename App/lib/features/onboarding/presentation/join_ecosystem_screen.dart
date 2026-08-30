import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/discovery_service.dart';
import '../../../application/pairing_service.dart';
import '../../../application/settings_service.dart';
import '../../../data/discovery/mdns_service.dart';

class JoinEcosystemScreen extends ConsumerStatefulWidget {
  const JoinEcosystemScreen({super.key});

  @override
  ConsumerState<JoinEcosystemScreen> createState() =>
      _JoinEcosystemScreenState();
}

class _JoinEcosystemScreenState extends ConsumerState<JoinEcosystemScreen> {
  final TextEditingController _ipController = TextEditingController();
  String? _selectedDeviceId;
  bool _isRequesting = false;
  bool _isConnectingManual = false;
  final Map<String, DiscoveredPeer> _manualPeers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).start();
      ref.read(discoveryServiceProvider.notifier).broadcastPing();
      _scanCommonSubnets();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _scanCommonSubnets() async {
    final subnetsToScan = <String>{
      '192.168.1.',
      '192.168.0.',
      '192.168.29.',
      '192.168.43.',
      '172.20.10.',
    };

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4 && !addr.address.startsWith('127.')) {
            subnetsToScan.add('${parts[0]}.${parts[1]}.${parts[2]}.');
          }
        }
      }
    } catch (_) {}

    for (final subnet in subnetsToScan) {
      for (int i = 1; i <= 254; i += 30) {
        if (!mounted) return;
        final futures = <Future>[];
        for (int j = i; j < i + 30 && j <= 254; j++) {
          final ip = '$subnet$j';
          futures.add(_probeIpSilent(ip));
        }
        await Future.wait(futures);
      }
    }
  }

  Future<void> _probeIpSilent(String ip) async {
    final ports = [8080, 8081, 8082];
    for (final port in ports) {
      try {
        final res = await http
            .get(Uri.parse('http://$ip:$port/api/status'))
            .timeout(const Duration(milliseconds: 900));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final devId = data['ecosystemId'] as String? ?? 'host-$ip';
          final hostName = data['hostDeviceName'] as String? ?? 'Phone';
          final ecoName = data['ecosystemName'] as String? ?? '$hostName’s Ecosystem';
          final portalPort = (data['portalPort'] as num?)?.toInt() ?? port;

          final peer = DiscoveredPeer(
            deviceId: devId,
            displayName: hostName,
            platform: data['platform'] as String? ?? 'android',
            address: ip,
            port: portalPort,
            protocolVersion: 1,
            ecosystemHint: ecoName,
            capabilities: ['clipboard', 'file', 'link'],
          );

          ref.read(discoveryServiceProvider.notifier).registerDiscoveredPeer(peer);

          if (mounted) {
            setState(() {
              _manualPeers[devId] = peer;
              _selectedDeviceId ??= devId;
            });
          }
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _connectDirectIp() async {
    final rawInput = _ipController.text.trim();
    if (rawInput.isEmpty) return;

    var cleanIp = rawInput.replaceAll(RegExp(r'https?://'), '').trim();
    int port = 8080;
    if (cleanIp.contains(':')) {
      final parts = cleanIp.split(':');
      cleanIp = parts[0];
      port = int.tryParse(parts[1]) ?? 8080;
    }

    setState(() => _isConnectingManual = true);
    try {
      final res = await http
          .get(Uri.parse('http://$cleanIp:$port/api/status'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final devId = data['ecosystemId'] as String? ?? 'phone-$cleanIp';
        final hostName = data['hostDeviceName'] as String? ?? 'Phone Host';
        final ecoName = data['ecosystemName'] as String? ?? '$hostName’s Ecosystem';
        final portalPort = (data['portalPort'] as num?)?.toInt() ?? port;

        final peer = DiscoveredPeer(
          deviceId: devId,
          displayName: hostName,
          platform: data['platform'] as String? ?? 'android',
          address: cleanIp,
          port: portalPort,
          protocolVersion: 1,
          ecosystemHint: ecoName,
          capabilities: ['clipboard', 'file', 'link'],
        );

        ref.read(discoveryServiceProvider.notifier).registerDiscoveredPeer(peer);

        if (mounted) {
          setState(() {
            _manualPeers[devId] = peer;
            _selectedDeviceId = devId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found "$ecoName" on $hostName!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not find host at $cleanIp:$port (HTTP ${res.statusCode})'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to $cleanIp:$port. Check that the phone app is open on same Wi-Fi.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingManual = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final peers = ref.watch(discoveryServiceProvider);

    final availableEcosystems = <String, DiscoveredPeer>{};
    for (final p in _manualPeers.values) {
      final key = p.ecosystemHint.isNotEmpty ? p.ecosystemHint : p.deviceId;
      availableEcosystems[key] = p;
    }
    for (final p in peers) {
      final key = p.peer.ecosystemHint.isNotEmpty
          ? p.peer.ecosystemHint
          : p.peer.deviceId;
      if (!availableEcosystems.containsKey(key)) {
        availableEcosystems[key] = p.peer;
      }
    }

    final ecoList = availableEcosystems.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Nearby Ecosystem'),
        leading: BackButton(onPressed: () => context.go('/welcome')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan Network',
            onPressed: () {
              ref.read(discoveryServiceProvider.notifier).broadcastPing();
              _scanCommonSubnets();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scanning local network for your phone…'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Manual IP Connect Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect with Phone IP Address',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open the app on your phone to see its IP (e.g. 192.168.1.50):',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              hintText: '192.168.1.xxx',
                              prefixIcon: const Icon(Icons.router_outlined, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onSubmitted: (_) => _connectDirectIp(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isConnectingManual ? null : _connectDirectIp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isConnectingManual
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Connect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovered Ecosystems',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Expanded(
                child: ecoList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_find_rounded,
                              size: 48,
                              color: AppColors.accent,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Searching for your phone on Wi‑Fi…',
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Make sure your phone is connected to the same Wi‑Fi\nand has Local Ecosystem open.',
                              textAlign: TextAlign.center,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: ecoList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (ctx, i) {
                          final peer = ecoList[i];
                          final isSelected =
                              _selectedDeviceId == peer.deviceId;
                          final displayName = peer.displayName.isNotEmpty
                              ? peer.displayName
                              : peer.deviceId;
                          final ecoName = peer.ecosystemHint.isNotEmpty
                              ? peer.ecosystemHint
                              : '$displayName’s Ecosystem';

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.12)
                                  : cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : cs.outline.withValues(alpha: 0.4),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.smartphone_rounded,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                ecoName,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Hosted on $displayName (${peer.address})',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: Radio<String>(
                                value: peer.deviceId,
                                groupValue: _selectedDeviceId,
                                onChanged: (v) =>
                                    setState(() => _selectedDeviceId = v),
                              ),
                              onTap: () => setState(
                                  () => _selectedDeviceId = peer.deviceId),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Request to Join Button
              ElevatedButton(
                onPressed: (_selectedDeviceId == null || _isRequesting)
                    ? null
                    : () {
                        final peer = ecoList.firstWhere(
                            (p) => p.deviceId == _selectedDeviceId);
                        _requestToJoin(peer);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRequesting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Waiting for approval on Phone…'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Request to Join Ecosystem'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestToJoin(DiscoveredPeer peer) async {
    setState(() => _isRequesting = true);
    try {
      final pairingService = ref.read(pairingServiceProvider);
      final result = await pairingService.sendPairingRequest(
        targetAddress: peer.address,
        targetPort: peer.port,
        targetDeviceId: peer.deviceId,
      );

      if (!mounted) return;

      switch (result) {
        case PairingApproved(
            peerName: final name,
            peerPublicKey: final _,
          ):
          final ecoName = peer.ecosystemHint.isNotEmpty
              ? peer.ecosystemHint
              : '$name’s Ecosystem';
          await SettingsService.instance.saveAndActivateEcosystem(
            id: peer.deviceId,
            name: ecoName,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully joined "$ecoName"!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/home');
          }
        case PairingRejected():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your request to join was declined by the host.'),
              backgroundColor: AppColors.danger,
            ),
          );
        case PairingTimeout():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request timed out. Please check your phone screen and try again.'),
              backgroundColor: AppColors.warning,
            ),
          );
        case PairingError(message: final msg):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: $msg'),
              backgroundColor: AppColors.danger,
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }
}
