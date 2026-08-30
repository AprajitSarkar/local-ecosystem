// lib/features/settings/presentation/crash_logs_screen.dart
// Dedicated screen to view, copy, and export crash logs across all ecosystem devices.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/logging/crash_reporting_service.dart';

class CrashLogsScreen extends StatefulWidget {
  const CrashLogsScreen({super.key});

  @override
  State<CrashLogsScreen> createState() => _CrashLogsScreenState();
}

class _CrashLogsScreenState extends State<CrashLogsScreen> {
  final _service = CrashReportingService.instance;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<CrashLogEntry>>(
      stream: _service.logsStream,
      initialData: _service.currentLogs,
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Crash Logs'),
            actions: [
              if (logs.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Export All Logs',
                  onPressed: () => _exportAll(logs),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Clear Logs',
                  onPressed: _confirmClear,
                ),
              ],
            ],
          ),
          body: logs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 36,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No Crashes Recorded',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The app is running smoothly. Any errors from your devices will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) => _CrashLogCard(entry: logs[i]),
                ),
        );
      },
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('This will delete all saved crash logs from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _service.clearLogs();
    }
  }

  void _exportAll(List<CrashLogEntry> logs) {
    final buffer = StringBuffer();
    buffer.writeln('=== LOCAL ECOSYSTEM CRASH LOG EXPORT ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}\n');

    for (final l in logs) {
      buffer.writeln('----------------------------------------');
      buffer.writeln('Device: ${l.deviceName} (${l.platform})');
      buffer.writeln('Timestamp: ${l.timestamp.toIso8601String()}');
      buffer.writeln('Error: ${l.errorSummary}');
      buffer.writeln('Stack Trace:\n${l.stackTrace}\n');
    }

    Share.share(buffer.toString(), subject: 'Local Ecosystem Crash Logs');
  }
}

class _CrashLogCard extends StatefulWidget {
  const _CrashLogCard({required this.entry});
  final CrashLogEntry entry;

  @override
  State<_CrashLogCard> createState() => _CrashLogCardState();
}

class _CrashLogCardState extends State<_CrashLogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = widget.entry;
    final formattedTime = DateFormat('MMM d, h:mm:ss a').format(l.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPlatformIcon(l.platform),
                        size: 14,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${l.deviceName} (${l.platform})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  formattedTime,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy Crash Log',
                  onPressed: () {
                    final text = '=== CRASH LOG ===\n'
                        'Device: ${l.deviceName} (${l.platform})\n'
                        'Time: $formattedTime\n'
                        'Error: ${l.errorSummary}\n\n'
                        'Stack Trace:\n${l.stackTrace}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Crash log copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Error Message
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, AppSpacing.sm),
            child: Text(
              l.errorSummary,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),

          // Stack Trace (Expandable)
          if (l.stackTrace.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(
                      _expanded ? 'Hide Stack Trace' : 'View Full Stack Trace',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Container(
                margin: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    l.stackTrace,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.phone_android_rounded;
      case 'ipad/ios':
      case 'ios':
        return Icons.tablet_mac_rounded;
      case 'linux':
      case 'windows':
      case 'macos':
        return Icons.laptop_chromebook_rounded;
      default:
        return Icons.devices_rounded;
    }
  }
}
