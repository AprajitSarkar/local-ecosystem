// lib/features/settings/presentation/receive_folder_screen.dart
// The user-configurable receive folder — the key feature requested.

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/settings_service.dart';

class ReceiveFolderScreen extends StatefulWidget {
  const ReceiveFolderScreen({super.key});

  @override
  State<ReceiveFolderScreen> createState() => _ReceiveFolderScreenState();
}

class _ReceiveFolderScreenState extends State<ReceiveFolderScreen> {
  final _settings = SettingsService.instance;
  String? _currentPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final path = await _settings.getReceiveFolder();
    if (mounted) setState(() { _currentPath = path; _loading = false; });
  }

  Future<void> _changePath() async {
    String? selected;

    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: use file picker to select a directory
      selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose receive folder',
      );
    } else {
      // Desktop: same
      selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose folder for received files',
      );
    }

    if (selected == null) return; // user cancelled

    // Ensure the directory exists
    try {
      await Directory(selected).create(recursive: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access that folder: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    await _settings.setReceiveFolder(selected);
    if (mounted) {
      setState(() => _currentPath = selected);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receive folder updated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _loading = true);
    // Clear saved preference so it falls back to platform default
    await _settings.setReceiveFolder('');
    final path = await _settings.getReceiveFolder();
    if (mounted) setState(() { _currentPath = path; _loading = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to default folder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Folder')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Info card ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'All files received from trusted devices are automatically saved here. No per-transfer prompts.',
                            style: tt.bodySmall?.copyWith(
                                color: cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Current folder ────────────────────────────────────
                  Text('Current folder', style: tt.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_open_outlined,
                              size: 22, color: AppColors.accent),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _folderDisplayName(_currentPath ?? ''),
                                style: tt.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _currentPath ?? '',
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Actions ───────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _changePath,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose Different Folder'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Reset to Default'),
                  ),

                  const Spacer(),

                  // ── Platform note ─────────────────────────────────────
                  _platformNote(context),
                  const SizedBox(height: AppSpacing.base),
                ],
              ),
            ),
    );
  }

  String _folderDisplayName(String path) {
    if (path.isEmpty) return 'Not set';
    return path.split('/').last.isEmpty
        ? path
        : path.split('/').last;
  }

  Widget _platformNote(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final note = kIsWeb
        ? 'In the browser, received files are downloaded directly to your Downloads folder.'
        : Platform.isIOS
            ? 'On iOS, received files are saved in your app\'s Documents folder, accessible via the Files app.'
            : Platform.isAndroid
                ? 'On Android, files are saved to the selected folder. You may need to grant storage permission.'
                : 'Files are saved to the selected folder on your computer.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(note,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
