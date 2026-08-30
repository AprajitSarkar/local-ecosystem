import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/clipboard_sync_service.dart';
import '../../../application/media_control_service.dart';
import '../../../application/settings_service.dart';
import '../../../application/web_portal_server.dart';
import '../../../data/discovery/udp_broadcast_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final settings = SettingsService.instance;

    final devicesAsync = ref.watch(devicesStreamProvider);
    final onlineCount = ref
        .watch(connectionStatusProvider)
        .values
        .where((v) => v)
        .length;
    final latestClip = ref.watch(latestClipboardProvider).valueOrNull;
    final recentActivity = ref.watch(activityStreamProvider).valueOrNull ?? [];

    final totalDevices = devicesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(settings.ecosystemName, style: tt.titleLarge),
            Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.micro,
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: onlineCount > 0 ? AppColors.online : AppColors.offline,
                    shape: BoxShape.circle,
                    boxShadow: onlineCount > 0
                        ? [BoxShadow(
                            color: AppColors.online.withValues(alpha: 0.5),
                            blurRadius: 4)]
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  onlineCount > 0
                      ? '$onlineCount of $totalDevices device${totalDevices == 1 ? '' : 's'} online'
                      : totalDevices == 0
                          ? 'No devices paired'
                          : 'All devices offline',
                  style: tt.labelSmall?.copyWith(
                    color: onlineCount > 0
                        ? AppColors.online
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Device',
            onPressed: () => context.go('/devices'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // ── Quick Actions ─────────────────────────────────────────────────
          Text('Quick Actions',
              style: tt.titleSmall?.copyWith(letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _QuickAction(
                icon: Icons.devices_outlined,
                label: 'Add\nDevice',
                onTap: () => context.go('/devices'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickAction(
                icon: Icons.upload_file_outlined,
                label: 'Send\nFile',
                onTap: () => context.go('/transfers'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickAction(
                icon: Icons.link_rounded,
                label: 'Send\nLink',
                onTap: () => _showSendLinkDialog(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              _QuickAction(
                icon: Icons.content_paste_outlined,
                label: 'Clipboard\nSync',
                accent: settings.clipboardSyncEnabled,
                onTap: () => context.go('/settings'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Remote Media Player Card (if media playing on any connected device) ──
          const _RemoteMediaCard(),

          // ── Web Portal Access (for iPad / other browsers) ────────────────
          const _WebPortalCard(),
          const SizedBox(height: AppSpacing.xl),

          // ── Latest Clipboard ──────────────────────────────────────────────
          Text('Latest Clipboard',
              style: tt.titleSmall?.copyWith(letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          _ClipboardCard(event: latestClip),
          const SizedBox(height: AppSpacing.xl),

          // ── Recent Activity ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity',
                  style: tt.titleSmall?.copyWith(letterSpacing: 0.5)),
              TextButton(
                onPressed: () => context.go('/activity'),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recentActivity.isEmpty)
            _EmptyActivity()
          else
            ...recentActivity.take(5).map((e) => _ActivityRow(entry: e)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Material(
        color: accent
            ? AppColors.accent.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : cs.outline.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 22,
                    color: accent ? AppColors.accent : cs.onSurfaceVariant),
                const SizedBox(height: 5),
                Text(label,
                    textAlign: TextAlign.center,
                    style: tt.labelSmall?.copyWith(
                      fontSize: 10,
                      color: accent ? AppColors.accent : cs.onSurfaceVariant,
                      letterSpacing: 0,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClipboardCard extends StatelessWidget {
  const _ClipboardCard({required this.event});
  final dynamic event; // ClipboardEventTableData?

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (event == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.content_paste_outlined,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text('No clipboard events yet',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.content_paste_outlined,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 5),
              Text(event.sourceDeviceName ?? 'Unknown',
                  style: tt.labelSmall
                      ?.copyWith(color: AppColors.accent, letterSpacing: 0)),
              const Spacer(),
              Text(
                _timeAgo(event.timestamp),
                style: tt.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            event.textPreview ?? '',
            style: tt.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {/* TODO: copy to clipboard */},
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy again'),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return DateFormat.jm().format(t);
  }
}

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.timeline_outlined, size: 28, color: cs.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text('No activity yet', style: tt.bodyMedium),
          const SizedBox(height: 4),
          Text('Transfers and events will appear here.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.circle, size: 10, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(entry.description ?? '', style: tt.bodySmall),
          ),
          Text(
            _timeAgo(entry.timestamp),
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return DateFormat.jm().format(t);
  }
}

class _WebPortalCard extends StatelessWidget {
  const _WebPortalCard();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final server = WebPortalServer.instance;

    return AnimatedBuilder(
      animation: server,
      builder: (context, _) {
        if (!server.isRunning) return const SizedBox.shrink();

        final url = server.portalUrl;

        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.language_rounded,
                        size: 20, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('iPad & Web Access Live',
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Open in Safari on your iPad to connect',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        url,
                        style: tt.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Web Portal URL copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RemoteMediaCard extends StatelessWidget {
  const _RemoteMediaCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MediaControlService.instance,
      builder: (context, _) {
        final media = MediaControlService.instance.activeMedia;
        if (media == null) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${media.artist.isNotEmpty ? '${media.artist} • ' : ''}${media.deviceName}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: () {
                  final ips = UdpBroadcastService.knownPeerIps;
                  for (final ip in ips) {
                    MediaControlService.instance.sendMediaCommand(targetAddress: ip, action: 'PREVIOUS');
                  }
                },
              ),
              IconButton(
                icon: Icon(media.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                iconSize: 32,
                color: AppColors.accent,
                onPressed: () {
                  final ips = UdpBroadcastService.knownPeerIps;
                  for (final ip in ips) {
                    MediaControlService.instance.sendMediaCommand(targetAddress: ip, action: 'PLAY_PAUSE');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () {
                  final ips = UdpBroadcastService.knownPeerIps;
                  for (final ip in ips) {
                    MediaControlService.instance.sendMediaCommand(targetAddress: ip, action: 'NEXT');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showSendLinkDialog(BuildContext context) {
  final ctrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Send Link to Ecosystem'),
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
                const SnackBar(
                  content: Text('Link broadcasted to all active devices!'),
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
