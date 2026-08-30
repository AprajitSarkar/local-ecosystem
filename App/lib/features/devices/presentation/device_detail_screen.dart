import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/clipboard_sync_service.dart';
import '../../../application/discovery_service.dart';
import '../../../application/pairing_service.dart';
import '../../../domain/entities/device.dart';
import '../../remote_input/presentation/remote_input_screen.dart';

class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({super.key, required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final devicesAsync = ref.watch(devicesStreamProvider);
    final connStatus = ref.watch(connectionStatusProvider);
    final discoveredPeers = ref.watch(discoveryServiceProvider);

    return devicesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (devices) {
        final device = devices.where((d) => d.deviceId == deviceId).firstOrNull;
        if (device == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Device')),
            body: Center(
              child: Text('Device not found.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          );
        }

        final isOnline = connStatus[deviceId] ?? false;
        final plat = DevicePlatform.fromString(device.platform, device.displayName);

        return Scaffold(
          appBar: AppBar(
            title: Text(device.displayName),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                tooltip: 'Remove Device',
                onPressed: () => _confirmRemove(context, ref, device.displayName),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              // ── Device card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline, width: 0.5),
                ),
                child: Row(
                  children: [
                    _LargePlatformIcon(platform: plat),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.displayName, style: tt.headlineMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: AppMotion.micro,
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? AppColors.online
                                      : AppColors.offline,
                                  shape: BoxShape.circle,
                                  boxShadow: isOnline
                                      ? [BoxShadow(
                                          color: AppColors.online
                                              .withValues(alpha: 0.5),
                                          blurRadius: 5)]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: tt.bodySmall?.copyWith(
                                  color: isOnline
                                      ? AppColors.online
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Info ──────────────────────────────────────────────────
              _InfoSection(title: 'Platform', value: _platformLabel(plat)),
              _InfoSection(title: 'Trust Status', value: device.trustStatus),
              _InfoSection(
                title: 'Added',
                value: DateFormat('MMM d, yyyy').format(device.addedAt),
              ),
              if (device.lastSeen != null)
                _InfoSection(
                  title: 'Last Seen',
                  value: DateFormat('MMM d, yyyy · h:mm a')
                      .format(device.lastSeen!),
                ),
              const SizedBox(height: AppSpacing.xl),

              // ── Actions ───────────────────────────────────────────────
              if (isOnline) ...[
                if (!kIsWeb &&
                    (Platform.isAndroid || Platform.isIOS) &&
                    (plat == DevicePlatform.windows || plat == DevicePlatform.linux)) ...[
                  FilledButton.icon(
                    onPressed: () {
                      final onlinePeer = discoveredPeers
                          .where((p) =>
                              p.peer.deviceId == device.deviceId ||
                              p.peer.displayName.toLowerCase() ==
                                  device.displayName.toLowerCase())
                          .firstOrNull;
                      if (onlinePeer != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RemoteInputScreen(peer: onlinePeer.peer),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Device must be actively connected on Wi‑Fi.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.touch_app_rounded),
                    label: const Text('Remote Trackpad & Keyboard'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                ElevatedButton.icon(
                  onPressed: () => context.go('/transfers'),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text('Send File to ${device.displayName}'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _showSendLinkDialog(context, device.displayName),
                  icon: const Icon(Icons.link_rounded),
                  label: Text('Send Link to ${device.displayName}'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Remove ────────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () =>
                    _confirmRemove(context, ref, device.displayName),
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.danger),
                label: const Text('Remove from Ecosystem'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text(
            '"$name" will be removed. It will no longer be trusted by this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(pairingServiceProvider).removeDevice(deviceId);
      if (context.mounted) context.go('/devices');
    }
  }

  void _showSendLinkDialog(BuildContext context, String deviceName) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Send Link to $deviceName'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                ClipboardSyncService.instance.broadcastLink(url);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Link sent to $deviceName!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  static String _platformLabel(DevicePlatform plat) => switch (plat) {
        DevicePlatform.android => 'Android',
        DevicePlatform.ios => 'iPhone / iPad',
        DevicePlatform.linux => 'Linux',
        DevicePlatform.windows => 'Windows',
        DevicePlatform.unknown => 'Unknown',
      };
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LargePlatformIcon extends StatelessWidget {
  const _LargePlatformIcon({required this.platform});
  final DevicePlatform platform;

  @override
  Widget build(BuildContext context) {
    final icon = switch (platform) {
      DevicePlatform.android => Icons.phone_android,
      DevicePlatform.ios     => Icons.phone_iphone,
      DevicePlatform.linux   => Icons.laptop_chromebook,
      DevicePlatform.windows => Icons.laptop_windows,
      DevicePlatform.unknown => Icons.device_unknown_outlined,
    };
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Icon(icon, size: 30, color: AppColors.accent),
    );
  }
}
