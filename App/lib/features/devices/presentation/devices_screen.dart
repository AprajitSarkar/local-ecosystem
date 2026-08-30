import 'dart:convert';
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
import '../../../core/web/web_pwa_service.dart';
import '../../../data/discovery/mdns_service.dart';
import '../../../data/local/database.dart';
import '../../../data/security/device_identity.dart';
import '../../../domain/entities/device.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start discovery when screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).start();
      _listenForIncomingPairings();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _listenForIncomingPairings() {
    final pairingService = ref.read(pairingServiceProvider);
    pairingService.incomingRequests.listen((request) {
      if (mounted) _showPairingRequest(request);
    });
  }

  bool _isJoining = false;

  Future<void> _requestJoinHost() async {
    setState(() => _isJoining = true);
    final approved = await WebPwaService.instance.requestJoinEcosystem();
    if (!mounted) return;
    setState(() => _isJoining = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved
            ? '✅ Successfully joined ${WebPwaService.instance.hostDeviceName}\'s Ecosystem!'
            : '❌ Request declined or timed out by host.'),
        backgroundColor: approved ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final trustedDevices = ref.watch(devicesStreamProvider);
    final discoveredPeers = ref.watch(discoveryServiceProvider);
    final connStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      body: Column(
        children: [
          if (kIsWeb)
            AnimatedBuilder(
              animation: WebPwaService.instance,
              builder: (ctx, _) {
                final pwa = WebPwaService.instance;
                if (!pwa.isJoined && pwa.hostDeviceName.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(AppSpacing.base),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hub_rounded, color: AppColors.accent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Host: ${pwa.hostDeviceName}',
                                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Request to join this ecosystem to sync files & clipboard.',
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isJoining ? null : _requestJoinHost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: _isJoining
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Join'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          Expanded(
            child: trustedDevices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (devices) {
          if (devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.devices_other_rounded,
                        size: 34,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No Devices in this Ecosystem',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap "Add Device" to scan and link other devices on your Wi‑Fi network.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddDeviceSheet(context, discoveredPeers),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add Device'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (ctx, i) {
              final d = devices[i];
              final online = connStatus[d.deviceId] ?? false;
              return _TrustedDeviceRow(
                device: d,
                isOnline: online,
                onTap: () => context.go('/devices/${d.deviceId}'),
              );
            },
          );
        },
      ),
    ),
  ],
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeviceSheet(context, discoveredPeers),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Device'),
      ),
    );
  }

  void _showAddDeviceSheet(
      BuildContext context, List<PeerState> peers) {
    ref.read(discoveryServiceProvider.notifier).broadcastPing();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddDeviceSheet(peers: peers),
    );
  }

  void _showPairingRequest(IncomingPairingRequest request) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => PairingRequestSheet(request: request),
    );
  }
}

// ── Trusted Device Row ────────────────────────────────────────────────────────

class _TrustedDeviceRow extends StatelessWidget {
  const _TrustedDeviceRow({
    required this.device,
    required this.isOnline,
    this.onTap,
  });
  final DeviceTableData device;
  final bool isOnline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final plat = DevicePlatform.fromString(device.platform, device.displayName);
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        leading: _PlatformIcon(platform: plat),
        title: Text(device.displayName, style: tt.titleMedium),
        subtitle: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.micro,
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                boxShadow: isOnline
                    ? [BoxShadow(
                        color: AppColors.online.withValues(alpha: 0.5),
                        blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isOnline
                  ? 'Online'
                  : device.lastSeen != null
                      ? 'Last seen ${_timeAgo(device.lastSeen!)}'
                      : 'Offline',
              style: tt.bodySmall?.copyWith(
                color: isOnline ? AppColors.online : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TrustBadge(trusted: device.trustStatus == TrustStatus.trusted.name),
          ],
        ),
        trailing: Icon(Icons.chevron_right,
            color: cs.onSurfaceVariant, size: 20),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.trusted});
  final bool trusted;

  @override
  Widget build(BuildContext context) {
    if (!trusted) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Trusted',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.success,
              fontSize: 10,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest, shape: BoxShape.circle),
              child: Icon(Icons.devices_outlined,
                  size: 36, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No devices yet', style: tt.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add a device on the same Wi‑Fi network.\nBoth devices must have the app running.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Device Sheet (real discovery) ────────────────────────────────────────

class _AddDeviceSheet extends ConsumerStatefulWidget {
  const _AddDeviceSheet({required this.peers});
  final List<PeerState> peers;

  @override
  ConsumerState<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends ConsumerState<_AddDeviceSheet> {
  final _pendingRequests = <String>{};
  final TextEditingController _ipController = TextEditingController();
  bool _isConnectingManual = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).broadcastPing();
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found "$hostName" ($ecoName)! Sending pairing request…'),
              backgroundColor: AppColors.success,
            ),
          );
          await _sendRequest(PeerState(peer: peer, isOnline: true));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not find device at $cleanIp:$port (HTTP ${res.statusCode})'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reach $cleanIp:$port. Check that the phone app is open on the same Wi‑Fi.'),
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
    final trustedDevicesList = ref.watch(devicesStreamProvider).valueOrNull ?? [];
    final trustedIds = trustedDevicesList.map((d) => d.deviceId).toSet();
    final trustedNames = trustedDevicesList.map((d) => d.displayName.toLowerCase().trim()).toSet();

    final myDeviceId = DeviceIdentityService.instance.currentDeviceId;
    final myName = SettingsService.instance.deviceName;

    // Filter out already-trusted peers and own device
    final untrustedPeers = peers.where((p) =>
        !trustedIds.contains(p.peer.deviceId) &&
        !trustedNames.contains(p.peer.displayName.toLowerCase().trim()) &&
        p.peer.deviceId != myDeviceId &&
        p.peer.displayName != myName).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.45,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nearby Devices', style: tt.titleLarge),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Rescan Network',
                      onPressed: () {
                        ref.read(discoveryServiceProvider.notifier).broadcastPing();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scanning local network for devices…'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    if (peers.isEmpty)
                      const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        '${peers.length} found',
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Connect to a phone or PC on your Wi‑Fi network:',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Direct IP Connect Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'Connect via IP (e.g. 192.168.1.50)',
                        hintStyle: TextStyle(fontSize: 12),
                        prefixIcon: Icon(Icons.router_outlined, size: 18),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _connectDirectIp(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _isConnectingManual ? null : _connectDirectIp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isConnectingManual
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Connect', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),
            Expanded(
              child: untrustedPeers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (peers.isEmpty) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Scanning network for your phone…', style: tt.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Make sure the app is open on your phone.',
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ] else ...[
                            Icon(Icons.wifi_find_outlined,
                                size: 40, color: cs.onSurfaceVariant),
                            const SizedBox(height: AppSpacing.sm),
                            Text('No new devices found.',
                                style: tt.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Make sure the phone has Local Ecosystem open.',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: untrustedPeers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) => _DiscoveredPeerRow(
                        peerState: untrustedPeers[i],
                        isPending: _pendingRequests
                            .contains(untrustedPeers[i].peer.deviceId),
                        onRequest: () =>
                            _sendRequest(untrustedPeers[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest(PeerState peerState) async {
    final peer = peerState.peer;
    setState(() => _pendingRequests.add(peer.deviceId));

    final pairingService = ref.read(pairingServiceProvider);
    final result = await pairingService.sendPairingRequest(
      targetAddress: peer.address,
      targetPort: peer.port,
      targetDeviceId: peer.deviceId,
    );

    if (!mounted) return;
    setState(() => _pendingRequests.remove(peer.deviceId));

    final msg = switch (result) {
      PairingApproved(peerName: final name) =>
        '"$name" is now trusted and part of your ecosystem.',
      PairingRejected() => 'Pairing was declined.',
      PairingTimeout() => 'No response — the request timed out.',
      PairingError(message: final m) => 'Error: $m',
    };

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: result is PairingApproved
              ? AppColors.success
              : AppColors.danger,
        ),
      );
      if (result is PairingApproved) Navigator.pop(context);
    }
  }
}

class _DiscoveredPeerRow extends StatelessWidget {
  const _DiscoveredPeerRow({
    required this.peerState,
    required this.isPending,
    required this.onRequest,
  });
  final PeerState peerState;
  final bool isPending;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final peer = peerState.peer;
    final plat = DevicePlatform.fromString(peer.platform, peer.displayName);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _PlatformIcon(platform: plat),
      title: Text(peer.displayName, style: tt.titleMedium),
      subtitle: Text(
        '${plat.name[0].toUpperCase()}${plat.name.substring(1)} · ${peer.address}',
        style: tt.bodySmall,
      ),
      trailing: isPending
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : OutlinedButton(
              onPressed: onRequest,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Request to Join'),
            ),
    );
  }
}

// ── Incoming Pairing Request Sheet ────────────────────────────────────────────

class PairingRequestSheet extends StatelessWidget {
  const PairingRequestSheet({super.key, required this.request});
  final IncomingPairingRequest request;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final plat = DevicePlatform.fromString(request.platform, request.displayName);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ─────────────────────────────────────────────────
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Device icon ────────────────────────────────────────────
            _PlatformIcon(platform: plat, size: 56),
            const SizedBox(height: AppSpacing.base),

            Text('New device wants to join',
                style: tt.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${request.displayName}"',
              style: tt.titleLarge?.copyWith(color: AppColors.accent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Trust explanation ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16,
                      color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'If you approve, this device will become trusted and can send files and clipboard updates without asking again.',
                      style: tt.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      request.respondWith(false);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.outline),
                      foregroundColor: cs.onSurface,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      request.respondWith(true);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '"${request.displayName}" is now trusted.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Components ─────────────────────────────────────────────────────────

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform, this.size = 40});
  final DevicePlatform platform;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = switch (platform) {
      DevicePlatform.android => Icons.phone_android,
      DevicePlatform.ios     => Icons.phone_iphone,
      DevicePlatform.linux   => Icons.laptop_chromebook,
      DevicePlatform.windows => Icons.laptop_windows,
      DevicePlatform.unknown => Icons.device_unknown_outlined,
    };
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.accent),
    );
  }
}
