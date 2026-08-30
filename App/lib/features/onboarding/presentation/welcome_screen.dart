// lib/features/onboarding/presentation/welcome_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/settings_service.dart';
import '../../../core/web/web_pwa_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_checkActiveEcosystem);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (SettingsService.instance.hasActiveEcosystem && mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_checkActiveEcosystem);
    super.dispose();
  }

  void _checkActiveEcosystem() {
    if (SettingsService.instance.hasActiveEcosystem && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final savedEcosystems = SettingsService.instance.savedEcosystems;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Icon & Title Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    size: 38,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Local Ecosystem',
                textAlign: TextAlign.center,
                style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect devices over your local Wi‑Fi.\nNo internet, accounts, or cloud required.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),

              // Feature badges
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: const [
                  _FeaturePill(icon: Icons.sync, label: 'Clipboard Sync'),
                  _FeaturePill(icon: Icons.send_rounded, label: 'Fast File Sharing'),
                  _FeaturePill(icon: Icons.lock_outline, label: 'Encrypted & Offline'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Saved Ecosystems (if any exist)
              if (savedEcosystems.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Your Saved Ecosystems',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${savedEcosystems.length} saved',
                      style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    itemCount: savedEcosystems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (ctx, i) {
                      final eco = savedEcosystems[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outline.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.devices_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            eco.name,
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Created ${DateFormat.MMMd().format(eco.createdAt)}',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: AppColors.danger,
                                ),
                                tooltip: 'Delete Ecosystem',
                                onPressed: () => _confirmDelete(eco),
                              ),
                              FilledButton.tonal(
                                onPressed: () async {
                                  await SettingsService.instance
                                      .switchEcosystem(eco.id);
                                  if (mounted) context.go('/home');
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Open'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),

              if (kIsWeb)
                _buildWebHostBanner(context),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () => context.go('/create-ecosystem'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create New Ecosystem'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go('/join-ecosystem'),
                icon: const Icon(Icons.wifi_find_rounded),
                label: const Text('Join Nearby Ecosystem'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebHostBanner(BuildContext context) {
    final hostName = WebPwaService.instance.hostDeviceName;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hostName.isNotEmpty ? 'Connected Host: $hostName' : 'Local Host Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap below to join this ecosystem and enable real-time clipboard and file sharing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/join-ecosystem'),
              icon: const Icon(Icons.hub_rounded),
              label: const Text('Join Ecosystem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(SavedEcosystem eco) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ecosystem?'),
        content: Text(
          'Are you sure you want to delete "${eco.name}"? This removes the local ecosystem record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await SettingsService.instance.deleteEcosystem(eco.id);
      setState(() {});
    }
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
