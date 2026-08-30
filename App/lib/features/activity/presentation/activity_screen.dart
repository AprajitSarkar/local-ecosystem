// lib/features/activity/presentation/activity_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/system_file_opener.dart';
import '../../../data/local/database.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final activityAsync = ref.watch(activityStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(activityStreamProvider),
          ),
        ],
      ),
      body: activityAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline_outlined,
                      size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No activity yet', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Clipboard syncs and file transfers will appear here.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.outline.withValues(alpha: 0.15),
            ),
            itemBuilder: (ctx, i) => _ActivityRow(entry: entries[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading activity: $err')),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final ActivityTableData entry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final (icon, color) = _iconFor(entry.type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        entry.description,
        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${entry.peerDeviceName ?? 'Local'} • ${DateFormat.jm().format(entry.timestamp)}',
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    );
  }

  (IconData, Color) _iconFor(String type) {
    switch (type) {
      case 'clipboard_received':
      case 'clipboard_sent':
        return (Icons.content_paste_rounded, AppColors.accent);
      case 'file_sent':
        return (Icons.upload_rounded, AppColors.accent);
      case 'file_received':
        return (Icons.download_rounded, AppColors.success);
      case 'device_paired':
        return (Icons.devices_rounded, AppColors.success);
      default:
        return (Icons.info_outline_rounded, AppColors.accent);
    }
  }
}
