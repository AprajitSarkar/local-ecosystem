// lib/features/settings/presentation/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../application/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Ecosystem ───────────────────────────────────────────────────
          _SectionHeader(title: 'Ecosystem'),
          _SettingsTile(
            icon: Icons.hub_outlined,
            title: 'Ecosystem Name',
            subtitle: _settings.ecosystemName,
            onTap: () => _editEcosystemName(context),
          ),
          _SettingsTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Switch Ecosystem',
            subtitle: '${_settings.savedEcosystems.length} saved ecosystems',
            onTap: () => _switchEcosystem(context),
          ),
          _SettingsTile(
            icon: Icons.exit_to_app_outlined,
            title: 'Leave Ecosystem',
            subtitle: 'Exit this ecosystem and return to setup',
            onTap: () => _confirmLeave(context),
            destructive: true,
          ),

          // ── Device ─────────────────────────────────────────────────────
          _SectionHeader(title: 'This Device'),
          _SettingsTile(
            icon: Icons.badge_outlined,
            title: 'Device Name',
            subtitle: _settings.deviceName,
            onTap: () => _editDeviceName(context),
          ),

          // ── Transfers ──────────────────────────────────────────────────
          _SectionHeader(title: 'Transfers'),
          _SettingsTile(
            icon: Icons.folder_outlined,
            title: 'Receive Folder',
            subtitle: 'Where incoming files are saved',
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/settings/receive-folder'),
          ),
          _ToggleTile(
            icon: Icons.verified_outlined,
            title: 'Auto-accept from trusted devices',
            subtitle: 'Skip confirmation for devices you\'ve already paired',
            value: _settings.autoAcceptTrusted,
            onChanged: (v) {
              _settings.setAutoAcceptTrusted(v);
              setState(() {});
            },
          ),

          // ── Clipboard ──────────────────────────────────────────────────
          _SectionHeader(title: 'Clipboard'),
          _ToggleTile(
            icon: Icons.content_paste_outlined,
            title: 'Clipboard Sync',
            subtitle: 'Sync clipboard text across trusted devices',
            value: _settings.clipboardSyncEnabled,
            onChanged: (v) {
              _settings.setClipboardSync(v);
              setState(() {});
            },
          ),

          // ── Links ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Links'),
          _ToggleTile(
            icon: Icons.open_in_browser_outlined,
            title: 'Auto-open received links',
            subtitle: 'Open URLs automatically in your default browser',
            value: _settings.autoOpenLinks,
            onChanged: (v) {
              _settings.setAutoOpenLinks(v);
              setState(() {});
            },
          ),

          // ── Appearance ─────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          _ToggleTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Use dark colour scheme',
            value: _settings.darkMode,
            onChanged: (v) {
              _settings.setDarkMode(v);
              setState(() {});
            },
          ),

          // ── Privacy & Security ─────────────────────────────────────────
          _SectionHeader(title: 'Privacy & Security'),
          _SettingsTile(
            icon: Icons.people_outline,
            title: 'Trusted Devices',
            subtitle: 'Manage paired devices',
            onTap: () => context.go('/devices'),
          ),

          // ── Diagnostics & Logs ─────────────────────────────────────────
          _SectionHeader(title: 'Diagnostics & Logs'),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'System & Crash Logs',
            subtitle: 'View, copy, and export error traces across ecosystem',
            onTap: () => context.go('/settings/crash-logs'),
          ),

          // ── About ──────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '0.1.0 · Protocol v1',
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Security',
            subtitle: 'End-to-end encrypted · LAN only · No cloud',
            onTap: null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _editEcosystemName(BuildContext context) async {
    final ctrl = TextEditingController(text: _settings.ecosystemName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ecosystem Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _settings.setEcosystemName(result);
      setState(() {});
    }
    ctrl.dispose();
  }

  Future<void> _editDeviceName(BuildContext context) async {
    final ctrl = TextEditingController(text: _settings.deviceName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Device Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _settings.setDeviceName(result);
      setState(() {});
    }
    ctrl.dispose();
  }

  Future<void> _switchEcosystem(BuildContext context) async {
    final ecosystems = _settings.savedEcosystems;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Switch Ecosystem',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (ecosystems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No other ecosystems saved.'),
                )
              else
                ...ecosystems.map((eco) {
                  final active = eco.id == _settings.ecosystemId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? AppColors.accent.withValues(alpha: 0.4)
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.3),
                        width: active ? 1 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        active
                            ? Icons.check_circle_rounded
                            : Icons.hub_outlined,
                        color: active ? AppColors.accent : null,
                      ),
                      title: Text(
                        eco.name,
                        style: TextStyle(
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? AppColors.accent : null,
                        ),
                      ),
                      trailing: active
                          ? const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                      onTap: () async {
                        await _settings.switchEcosystem(eco.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/create-ecosystem');
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create New Ecosystem'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Ecosystem?'),
        content: const Text(
          'You will exit the current ecosystem and return to the ecosystem selection screen.',
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _settings.leaveEcosystem();
      if (context.mounted) {
        context.go('/welcome');
      }
    }
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant, letterSpacing: 0.8),
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final color = destructive ? AppColors.danger : cs.onSurface;
    final iconColor = destructive ? AppColors.danger : AppColors.accent;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(title, style: tt.bodyMedium?.copyWith(color: color)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right,
                  size: 18, color: cs.onSurfaceVariant)
              : null),
    );
  }
}

// ─── Toggle Tile ──────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.accent),
      title: Text(title, style: tt.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
