import 'dart:async';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/discovery_service.dart';
import '../../../application/pending_share_service.dart';
import '../../../application/settings_service.dart';
import '../../../application/transfer_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/system_file_opener.dart';
import '../../../core/web/web_file_picker.dart';
import '../../../core/web/web_pwa_service.dart';
import '../../../data/discovery/mdns_service.dart';
import '../../../data/discovery/udp_broadcast_service.dart';
import '../../../data/transport/tcp_client.dart';
import '../../../domain/entities/transfer.dart';

class SelectedFileItem {
  SelectedFileItem({
    this.file,
    this.webFile,
    this.isSelected = true,
  }) : assert(file != null || webFile != null);

  final PlatformFile? file;
  final WebPickedFile? webFile;
  bool isSelected;

  String get name => webFile?.name ?? file!.name;
  int get size => webFile?.size ?? file!.size;
  String? get path => file?.path;
  Uint8List? get bytes => file?.bytes;
  Stream<List<int>>? get readStream => file?.readStream;
}

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen>
    with AutomaticKeepAliveClientMixin {
  final List<SelectedFileItem> _selectedFiles = [];
  String _selectedTarget = 'ECOSYSTEM'; // 'ECOSYSTEM' or specific deviceId
  bool _isSending = false;
  double _sendProgress = 0.0;
  String? _statusText;
  StreamSubscription<Transfer>? _transferSub;

  bool _isDragging = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).broadcastPing();
      ref.read(discoveryServiceProvider.notifier).broadcastNow();
      _transferSub = ref.read(transferServiceProvider).transferUpdates.listen((_) {
        if (mounted) setState(() {});
      });

      if (PendingShareService.instance.initialSharePaths.isNotEmpty) {
        final paths = List<String>.from(PendingShareService.instance.initialSharePaths);
        PendingShareService.instance.initialSharePaths.clear();
        _handleDroppedPaths(paths);
      }
    });
  }

  void _handleDroppedPaths(List<String> paths) {
    for (final pth in paths) {
      final cleanPath = pth.trim();
      if (cleanPath.isEmpty) continue;
      final dir = Directory(cleanPath);
      final file = File(cleanPath);

      if (dir.existsSync()) {
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is File) {
              final len = entity.lengthSync();
              final name = p.basename(entity.path);
              _selectedFiles.add(
                SelectedFileItem(
                  file: PlatformFile(
                    name: name,
                    path: entity.path,
                    size: len,
                  ),
                ),
              );
            }
          }
        } catch (e) {
          logger.warning('TransfersScreen', 'Error enumerating folder: $e');
        }
      } else if (file.existsSync()) {
        final len = file.lengthSync();
        final name = p.basename(file.path);
        _selectedFiles.add(
          SelectedFileItem(
            file: PlatformFile(
              name: name,
              path: file.path,
              size: len,
            ),
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickFolder() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        _handleDroppedPaths([selectedDirectory]);
      }
    } catch (e) {
      logger.warning('TransfersScreen', 'Error picking folder: $e');
    }
  }

  @override
  void dispose() {
    _transferSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final discoveredPeers = ref.watch(discoveryServiceProvider);
    final onlinePeers = discoveredPeers.where((p) => p.isOnline).toList();
    final recentTransfers = ref.watch(recentTransfersProvider).valueOrNull ?? [];
    final transferService = ref.watch(transferServiceProvider);
    final activeTransfers = ref.watch(activeTransfersProvider).valueOrNull ?? transferService.activeTransfers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Scan for Devices',
            onPressed: () {
              ref.read(discoveryServiceProvider.notifier).broadcastPing();
              ref.read(discoveryServiceProvider.notifier).broadcastNow();
            },
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Select Folder',
            onPressed: _pickFolder,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Select Files',
            onPressed: _pickFiles,
          ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (detail) => setState(() => _isDragging = true),
        onDragExited: (detail) => setState(() => _isDragging = false),
        onDragDone: (detail) {
          setState(() => _isDragging = false);
          final paths = detail.files.map((f) => f.path).toList();
          _handleDroppedPaths(paths);
        },
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
          // ── Preparing for Sharing Banner ──────────────────────────────────
          if (_isPreparing) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preparing for Sharing…',
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _preparingMessage ?? 'Allocating high-speed streaming buffers…',
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Active Ongoing Transfers (Real-Time Live UI) ─────────────────────
          if (activeTransfers.isNotEmpty || _isSending) ...[
            Row(
              children: [
                const Icon(Icons.sync_rounded, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Ongoing Transfers (${activeTransfers.isNotEmpty ? activeTransfers.length : 1})',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (activeTransfers.isNotEmpty)
              ...activeTransfers.map((t) => _ActiveTransferCard(transfer: t))
            else
              _GenericOngoingCard(statusText: _statusText, progress: _sendProgress),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Selected Files Section (Top) ──────────────────────────────────
          if (_selectedFiles.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.folder_copy_outlined,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Selected Files (${_selectedFiles.where((f) => f.isSelected).length}/${_selectedFiles.length})',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add More'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outline.withValues(alpha: 0.2),
                ),
                itemBuilder: (ctx, i) {
                  final item = _selectedFiles[i];
                  return ListTile(
                    leading: Checkbox(
                      value: item.isSelected,
                      onChanged: (v) =>
                          setState(() => item.isSelected = v ?? false),
                    ),
                    title: Text(
                      item.name,
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatBytes(item.size),
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () =>
                          setState(() => _selectedFiles.removeAt(i)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Destination Target Picker ─────────────────────────────────
            Text(
              'Choose Destination Target',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            
            // Ecosystem Broadcast Tile
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedTarget = 'ECOSYSTEM'),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedTarget == 'ECOSYSTEM'
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedTarget == 'ECOSYSTEM'
                        ? AppColors.accent
                        : cs.outline.withValues(alpha: 0.3),
                    width: _selectedTarget == 'ECOSYSTEM' ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Ecosystem Devices',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Broadcast to all active online devices (${onlinePeers.length} online)',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: 'ECOSYSTEM',
                      groupValue: _selectedTarget,
                      onChanged: (v) => setState(() => _selectedTarget = v!),
                    ),
                  ],
                ),
              ),
            ),

            if (onlinePeers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...onlinePeers.map((p) {
                final isSelected = _selectedTarget == p.peer.deviceId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selectedTarget = p.peer.deviceId),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : cs.outline.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getDeviceIcon(p.peer.platform),
                              color: isSelected
                                  ? AppColors.accent
                                  : cs.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.peer.displayName,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${p.peer.platform.toUpperCase()} • ${p.peer.address}',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: p.peer.deviceId,
                            groupValue: _selectedTarget,
                            onChanged: (v) =>
                                setState(() => _selectedTarget = v!),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: AppSpacing.md),

            // ── Send Action Button ─────────────────────────────────────────
            if (!_isSending) ...[
              ElevatedButton.icon(
                onPressed: _selectedFiles.any((f) => f.isSelected)
                    ? () => _sendSelectedFiles(onlinePeers)
                    : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  'Send ${_selectedFiles.where((f) => f.isSelected).length} File(s)',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            // ── Empty State / Pick Action Card ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      size: 32,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Share Files Directly Over LAN',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High speed zero-cloud transfers to any device on your Wi-Fi.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Select Files'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickFolder,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('Select Folder'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '💡 Or simply drag & drop files and folders anywhere',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── Transfer History Section (Tap to Open) ────────────────────────
          Row(
            children: [
              Text(
                'Transfer History',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Tap to open file',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          if (recentTransfers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No file transfers yet',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...recentTransfers.map((t) => _TransferHistoryRow(data: t)),
        ],
      ),
      if (_isDragging)
        Positioned.fill(
          child: Container(
            color: cs.surface.withValues(alpha: 0.92),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.xl),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.file_download_outlined, size: 72, color: AppColors.accent),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Drop Files or Folders Here',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Items will be instantly queued for sharing across your ecosystem',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  ),
),
);
  }

  static String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0s';
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes < 60) {
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    if (hours < 24) {
      return remMinutes > 0 ? '${hours}h ${remMinutes}m' : '${hours}h';
    }
    final days = hours ~/ 24;
    final remHours = hours % 24;
    return remHours > 0 ? '${days}d ${remHours}h' : '${days}d';
  }

  bool _isPicking = false;
  bool _isPreparing = false;
  String? _preparingMessage;

  Future<void> _pickFiles() async {
    if (_isPicking) return;
    _isPicking = true;
    setState(() {
      _isPreparing = true;
      _preparingMessage = 'Accessing file storage…';
    });
    try {
      if (kIsWeb) {
        final webPicked = await pickFilesWeb();
        if (webPicked.isEmpty) {
          setState(() {
            _isPreparing = false;
            _preparingMessage = null;
          });
          return;
        }

        setState(() {
          for (final f in webPicked) {
            if (!_selectedFiles.any((existing) => existing.name == f.name && existing.size == f.size)) {
              _selectedFiles.add(SelectedFileItem(webFile: f, isSelected: true));
            }
          }
          _isPreparing = false;
          _preparingMessage = null;
        });
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
        allowCompression: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isPreparing = false;
          _preparingMessage = null;
        });
        return;
      }

      setState(() {
        _preparingMessage = 'Preparing ${result.files.length} selected file(s)…';
      });

      setState(() {
        for (final f in result.files) {
          final id = f.path ?? f.name;
          if (!_selectedFiles.any((existing) => (existing.path ?? existing.name) == id)) {
            _selectedFiles.add(SelectedFileItem(file: f, isSelected: true));
          }
        }
        _isPreparing = false;
        _preparingMessage = null;
      });
    } catch (e) {
      logger.error('TransfersScreen', 'Error picking files', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick files: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      _isPicking = false;
      if (mounted) {
        setState(() {
          _isPreparing = false;
          _preparingMessage = null;
        });
      }
    }
  }

  Future<void> _sendSelectedFiles(List<PeerState> onlinePeers) async {
    final filesToSend =
        _selectedFiles.where((f) => f.isSelected && (kIsWeb || f.path != null)).toList();
    if (filesToSend.isEmpty) return;

    if (kIsWeb) {
      final hostUrl = WebPwaService.instance.hostUrl.isNotEmpty
          ? WebPwaService.instance.hostUrl
          : Uri.base.origin;

      setState(() {
        _isSending = true;
        _sendProgress = 0.01;
        _statusText = 'Preparing stream to host…';
      });

      try {
        for (int i = 0; i < filesToSend.length; i++) {
          final item = filesToSend[i];
          final senderName = WebPwaService.instance.webDisplayName;
          final uploadUrl = '$hostUrl/api/transfer_stream';

          setState(() {
            _statusText = 'Streaming "${item.name}" (0%)…';
            _sendProgress = 0.0;
          });

          if (item.webFile != null) {
            await uploadFileWeb(
              file: item.webFile!,
              uploadUrl: uploadUrl,
              senderName: senderName,
              onProgress: (progress, speedMB, status) {
                if (mounted) {
                  setState(() {
                    _sendProgress = progress;
                    _statusText = status;
                  });
                }
              },
            );
          } else {
            final stream = item.readStream ??
                (item.bytes != null ? Stream.value(item.bytes!) : null);
            if (stream == null) continue;

            final req = http.StreamedRequest('POST', Uri.parse(uploadUrl));
            req.headers['X-Filename'] = Uri.encodeComponent(item.name);
            req.headers['X-Total-Bytes'] = item.size.toString();
            req.headers['X-Sender-Device-Name'] = Uri.encodeComponent(senderName);
            if (item.size > 0) req.contentLength = item.size;

            final controller = StreamController<List<int>>();
            stream.listen(
              (chunk) => controller.add(chunk),
              onDone: () => controller.close(),
              onError: (err) => controller.addError(err),
              cancelOnError: true,
            );
            controller.stream.listen(
              (chunk) => req.sink.add(chunk),
              onDone: () => req.sink.close(),
              onError: (err) => req.sink.addError(err),
              cancelOnError: true,
            );

            final streamedRes = await req.send();
            if (streamedRes.statusCode != 200) {
              throw Exception('Upload failed with HTTP ${streamedRes.statusCode}');
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Successfully transferred ${filesToSend.length} file(s) to host!'),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _selectedFiles.clear();
            _isSending = false;
            _statusText = null;
          });
        }
      } catch (e) {
        logger.error('TransfersScreen', 'Streaming upload failed', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
          setState(() {
            _isSending = false;
            _statusText = null;
          });
        }
      }
      return;
    }

    ref.read(discoveryServiceProvider.notifier).broadcastPing();
    ref.read(discoveryServiceProvider.notifier).broadcastNow();

    final targetPeers = <DiscoveredPeer>[];
    if (_selectedTarget == 'ECOSYSTEM') {
      for (final p in onlinePeers) {
        if (!targetPeers.any((t) => t.deviceId == p.peer.deviceId || t.address == p.peer.address)) {
          targetPeers.add(p.peer);
        }
      }
      final allDiscovered = ref.read(discoveryServiceProvider);
      for (final p in allDiscovered) {
        if (!targetPeers.any((t) => t.deviceId == p.peer.deviceId || t.address == p.peer.address)) {
          targetPeers.add(p.peer);
        }
      }
      for (final ip in UdpBroadcastService.knownPeerIps) {
        if (!targetPeers.any((t) => t.address == ip)) {
          targetPeers.add(DiscoveredPeer(
            deviceId: 'peer-$ip',
            displayName: 'Ecosystem Device ($ip)',
            platform: 'unknown',
            address: ip,
            port: 51413,
            protocolVersion: 1,
            ecosystemHint: '',
            capabilities: const ['clipboard', 'file', 'link'],
          ));
        }
      }
    } else {
      final match =
          onlinePeers.where((p) => p.peer.deviceId == _selectedTarget);
      if (match.isNotEmpty) {
        targetPeers.add(match.first.peer);
      } else {
        final allDiscovered = ref.read(discoveryServiceProvider);
        final fallback =
            allDiscovered.where((p) => p.peer.deviceId == _selectedTarget);
        if (fallback.isNotEmpty) targetPeers.add(fallback.first.peer);
      }
    }

    if (targetPeers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active ecosystem devices found on Wi-Fi.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _sendProgress = 0.05;
      _statusText = 'Starting transfer…';
    });

    try {
      final transferService = ref.read(transferServiceProvider);
      for (int i = 0; i < filesToSend.length; i++) {
        final item = filesToSend[i];
        for (final target in targetPeers) {
          if (mounted) {
            setState(() {
              _statusText = 'Connecting to ${target.displayName}…';
              _sendProgress = 0.05;
            });
          }

          final isWebPeer = target.platform == 'web' ||
              target.platform == 'ios' && target.port == 8080 ||
              target.deviceId.startsWith('web') ||
              target.port == 8080;

          final conn = PeerConnection(
            deviceId: target.deviceId,
            address: target.address,
            port: target.port > 0 ? target.port : (isWebPeer ? 8080 : 51413),
          );

          try {
            if (!isWebPeer) {
              try {
                await conn.connect();
              } catch (connErr) {
                logger.info('TransfersScreen', 'TCP connect failed ($connErr), falling back to HTTP stream');
              }
            }

            final sub = transferService.transferUpdates.listen((update) {
              if (mounted && update.progress != null) {
                setState(() {
                  _sendProgress = update.progress!.percentage;
                  final speedMb = (update.progress!.speedBytesPerSec /
                          (1024 * 1024))
                      .toStringAsFixed(1);
                  _statusText =
                      'Sending "${item.name}" ($speedMb MB/s) • ${(update.progress!.percentage * 100).toInt()}%';
                });
              }
            });

            await transferService.sendFile(
              filePath: item.path!,
              connection: conn,
              peerDeviceId: target.deviceId,
              peerDeviceName: target.displayName,
            );

            await sub.cancel();
          } catch (e) {
            logger.warning('TransfersScreen', 'Failed to send to ${target.displayName}: $e');
          } finally {
            try {
              await conn.disconnect();
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Successfully transferred ${filesToSend.length} file(s)!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedFiles.clear();
          _isSending = false;
          _sendProgress = 0.0;
          _statusText = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() {
          _isSending = false;
          _sendProgress = 0.0;
          _statusText = null;
        });
      }
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getDeviceIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.phone_android_rounded;
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

class _TransferHistoryRow extends StatelessWidget {
  const _TransferHistoryRow({required this.data});
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final filename = data.filename as String? ?? 'File';
    final totalBytes = (data.totalBytes as num?)?.toInt() ?? 0;
    final direction = data.direction as String? ?? 'outgoing';
    final peerName = data.peerDeviceName as String? ?? 'Device';
    final state = data.state as String? ?? 'completed';
    final localPath = data.localPath as String?;
    final isIncoming = direction == 'incoming';
    final isComplete = state == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(filename),
                color: isComplete ? AppColors.success : AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatBytes(totalBytes)} • ${isIncoming ? 'Received from' : 'Sent to'} $peerName',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (localPath != null && localPath.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.folder_open_rounded, size: 20),
                    tooltip: 'Show in Folder',
                    onPressed: () => SystemFileOpener.openFolder(localPath),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    tooltip: 'Open File',
                    onPressed: () => SystemFileOpener.open(localPath),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    tooltip: 'Share',
                    onPressed: () =>
                        Share.shareXFiles([XFile(localPath)]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.movie_outlined;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return Icons.audiotrack_outlined;
      case 'doc':
      case 'docx':
      case 'txt':
        return Icons.description_outlined;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _ActiveTransferCard extends StatelessWidget {
  const _ActiveTransferCard({required this.transfer});
  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final prog = transfer.progress;
    final isIncoming = transfer.direction == TransferDirection.incoming;

    final bytesDone = prog?.bytesTransferred ?? 0;
    final totalBytes = transfer.totalBytes > 0 ? transfer.totalBytes : (prog?.totalBytes ?? 0);
    final pct = totalBytes > 0 ? (bytesDone / totalBytes).clamp(0.0, 1.0) : (prog?.percentage ?? 0.0);
    final speedBytes = prog?.speedBytesPerSec ?? 0.0;
    final speedMBps = (speedBytes / (1024 * 1024)).toStringAsFixed(1);
    final speedMbps = ((speedBytes * 8) / (1000 * 1000)).toStringAsFixed(1);
    final eta = prog?.etaSeconds;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncoming ? Icons.download_rounded : Icons.upload_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.filename,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isIncoming
                          ? '📥 Receiving from ${transfer.peerDeviceName}'
                          : '🚀 Sending to ${transfer.peerDeviceName}',
                      style: tt.labelSmall?.copyWith(
                        color: isIncoming ? AppColors.success : AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (speedBytes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⚡ $speedMBps MB/s ($speedMbps Mbps)',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct > 0 ? pct : null,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_TransfersScreenState._formatBytes(bytesDone)} / ${_TransfersScreenState._formatBytes(totalBytes)} • ${(pct * 100).toStringAsFixed(1)}%',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (eta != null && eta > 0)
                Text(
                  '~${_TransfersScreenState.formatDuration(eta)} remaining',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenericOngoingCard extends StatelessWidget {
  const _GenericOngoingCard({required this.statusText, required this.progress});
  final String? statusText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText ?? 'Transferring files across LAN…',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% complete • Streaming over zero-loss LAN',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
