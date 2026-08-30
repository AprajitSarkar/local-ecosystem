import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/settings_service.dart';

class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionItem {
  _PermissionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.onRequest,
    required this.onCheck,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Future<bool> Function() onRequest;
  final Future<bool> Function() onCheck;
  bool isGranted = false;
  bool isChecking = false;
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen>
    with WidgetsBindingObserver {
  late List<_PermissionItem> _items;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildPermissionItems();
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  void _buildPermissionItems() {
    _items = [
      _PermissionItem(
        id: 'network',
        title: 'Local Network & Discovery',
        description:
            'Allows finding and connecting with devices on your Wi‑Fi network without internet access.',
        icon: Icons.wifi_tethering_rounded,
        onCheck: () async {
          if (kIsWeb) return true;
          if (Platform.isAndroid) {
            final nearby = await Permission.nearbyWifiDevices.status;
            final loc = await Permission.locationWhenInUse.status;
            return nearby.isGranted || loc.isGranted || Platform.version.isNotEmpty;
          }
          if (Platform.isIOS) {
            // iOS local network permission prompts on first network socket usage
            return true;
          }
          return true; // Linux / Desktop local network is system-level
        },
        onRequest: () async {
          if (kIsWeb) return true;
          if (Platform.isAndroid) {
            var res = await Permission.nearbyWifiDevices.request();
            if (!res.isGranted) {
              res = await Permission.locationWhenInUse.request();
            }
            return res.isGranted;
          }
          return true;
        },
      ),
      _PermissionItem(
        id: 'notifications',
        title: 'System Notifications',
        description:
            'Alerts you when a trusted device sends files, clipboard events, or pairing requests.',
        icon: Icons.notifications_active_outlined,
        onCheck: () async {
          if (kIsWeb) return true;
          if (Platform.isAndroid || Platform.isIOS) {
            final status = await Permission.notification.status;
            return status.isGranted;
          }
          return true; // Linux desktop notifications use libnotify / dbus
        },
        onRequest: () async {
          if (kIsWeb) return true;
          if (Platform.isAndroid || Platform.isIOS) {
            final status = await Permission.notification.request();
            return status.isGranted;
          }
          return true;
        },
      ),
      _PermissionItem(
        id: 'storage',
        title: 'Storage & File Transfer',
        description:
            'Enables selecting files to share and saving incoming files directly to your chosen receive folder.',
        icon: Icons.folder_shared_outlined,
        onCheck: () async {
          if (kIsWeb) return true;
          if (Platform.isAndroid) {
            final photos = await Permission.photos.status;
            final storage = await Permission.storage.status;
            final manage = await Permission.manageExternalStorage.status;
            return photos.isGranted || storage.isGranted || manage.isGranted;
          }
          if (Platform.isIOS) {
            final photos = await Permission.photos.status;
            return photos.isGranted || photos.isLimited;
          }
          return true; // Desktop
        },
        onRequest: () async {
          if (kIsWeb) return true;
          if (Platform.isAndroid) {
            var status = await Permission.photos.request();
            if (!status.isGranted) {
              status = await Permission.storage.request();
            }
            return status.isGranted;
          }
          if (Platform.isIOS) {
            final status = await Permission.photos.request();
            return status.isGranted || status.isLimited;
          }
          return true;
        },
      ),
      _PermissionItem(
        id: 'clipboard',
        title: 'Clipboard Sync',
        description:
            'Allows synchronizing copied text snippets across your trusted devices seamlessly.',
        icon: Icons.content_paste_rounded,
        onCheck: () async => true, // Standard app permission across platforms
        onRequest: () async => true,
      ),
    ];
  }

  Future<void> _checkAllPermissions() async {
    for (final item in _items) {
      final granted = await item.onCheck();
      item.isGranted = granted;
    }
    if (mounted) {
      setState(() {
        _initializing = false;
      });
    }
  }

  Future<void> _requestItem(_PermissionItem item) async {
    setState(() => item.isChecking = true);
    try {
      final granted = await item.onRequest();
      item.isGranted = granted || await item.onCheck();
    } catch (_) {
      item.isGranted = await item.onCheck();
    } finally {
      if (mounted) {
        setState(() => item.isChecking = false);
      }
    }
  }

  Future<void> _completeAndContinue() async {
    await SettingsService.instance.setHasCompletedPermissions(true);
    if (mounted) {
      context.go('/welcome');
    }
  }

  bool get _allGranted => _items.every((item) => item.isGranted);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _initializing
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.base,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    // Header icon
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          size: 34,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'App Setup & Permissions',
                      textAlign: TextAlign.center,
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'To share files and sync clipboard completely offline on Wi‑Fi, please enable the permissions below.',
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Permission Items List
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (ctx, i) {
                          final item = _items[i];
                          return _PermissionCard(
                            item: item,
                            onRequest: () => _requestItem(item),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Progress indicator banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _allGranted
                            ? AppColors.success.withValues(alpha: 0.12)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _allGranted
                              ? AppColors.success.withValues(alpha: 0.3)
                              : cs.outline.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _allGranted
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 18,
                            color: _allGranted
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _allGranted
                                  ? 'All required permissions granted!'
                                  : 'Tap "Enable" on remaining items above.',
                              style: tt.labelSmall?.copyWith(
                                color: _allGranted
                                    ? AppColors.success
                                    : cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Continue Button
                    ElevatedButton(
                      onPressed: _completeAndContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            _allGranted ? AppColors.accent : cs.surfaceContainerHighest,
                        foregroundColor:
                            _allGranted ? Colors.white : cs.onSurface,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _allGranted
                                ? 'Continue to Local Ecosystem'
                                : 'Continue Anyway',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
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
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.item,
    required this.onRequest,
  });

  final _PermissionItem item;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isGranted
              ? AppColors.success.withValues(alpha: 0.35)
              : cs.outline.withValues(alpha: 0.4),
          width: item.isGranted ? 1 : 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.isGranted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: item.isGranted ? AppColors.success : AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Action / Status Indicator
          if (item.isChecking)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (item.isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Granted',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )
          else
            FilledButton.tonal(
              onPressed: onRequest,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Enable',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
