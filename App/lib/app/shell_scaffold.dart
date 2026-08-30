// lib/app/shell_scaffold.dart
// Responsive shell — native desktop sidebar (Linux/macOS/Windows), rail (tablet/iPad), bottom nav (phone)
// Uses StatefulNavigationShell to preserve full state across all tabs without re-initializing.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../application/settings_service.dart';
import '../core/web/web_pwa_service.dart';
import 'theme/app_theme.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WebPwaService.instance.checkAndShowInstallPrompt(context);
      });
    }

    final width = MediaQuery.sizeOf(context).width;
    final isDesktopPlatform =
        !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

    Widget layout;
    if (isDesktopPlatform) {
      if (width < 700) {
        layout = _TabletLayout(navigationShell: navigationShell);
      } else {
        layout = _DesktopLayout(navigationShell: navigationShell);
      }
    } else if (width >= 1024) {
      layout = _DesktopLayout(navigationShell: navigationShell);
    } else if (width >= 600) {
      layout = _TabletLayout(navigationShell: navigationShell);
    } else {
      layout = _PhoneLayout(navigationShell: navigationShell);
    }

    if (!kIsWeb) return layout;

    return Stack(
      children: [
        layout,
        const _HostOfflineBanner(),
      ],
    );
  }
}

// ─── Destinations ─────────────────────────────────────────────────────────────

const _destinations = [
  _NavDestination(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      path: '/home'),
  _NavDestination(
      label: 'Devices',
      icon: Icons.devices_outlined,
      activeIcon: Icons.devices_rounded,
      path: '/devices'),
  _NavDestination(
      label: 'Transfers',
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz_rounded,
      path: '/transfers'),
  _NavDestination(
      label: 'Activity',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_toggle_off_rounded,
      path: '/activity'),
  _NavDestination(
      label: 'Settings',
      icon: Icons.tune_rounded,
      activeIcon: Icons.tune_rounded,
      path: '/settings'),
];

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}

// ─── Phone Layout ─────────────────────────────────────────────────────────────

class _PhoneLayout extends StatelessWidget {
  const _PhoneLayout({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

// ─── Tablet / iPad Layout ─────────────────────────────────────────────────────

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            labelType: NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
            ),
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          VerticalDivider(width: 1, color: cs.outline.withValues(alpha: 0.3)),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ─── Desktop Layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: _SidebarNav(navigationShell: navigationShell),
          ),
          VerticalDivider(
            width: 1,
            color: cs.outline.withValues(alpha: 0.3),
          ),
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNav extends StatelessWidget {
  const _SidebarNav({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final settings = SettingsService.instance;

    return Material(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // App Title + Ecosystem Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local Ecosystem',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        settings.ecosystemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: cs.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _destinations.length,
              itemBuilder: (ctx, i) {
                final d = _destinations[i];
                final isSelected = navigationShell.currentIndex == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: isSelected
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    leading: Icon(
                      isSelected ? d.activeIcon : d.icon,
                      color: isSelected
                          ? AppColors.accent
                          : cs.onSurfaceVariant,
                      size: 20,
                    ),
                    title: Text(
                      d.label,
                      style: tt.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.accent
                            : cs.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == navigationShell.currentIndex,
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer info
          Divider(
            height: 1,
            color: cs.outline.withValues(alpha: 0.2),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Encrypted LAN Zero-Cloud',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final settings = SettingsService.instance;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(
            'Online • ${settings.deviceName}',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Local Wi-Fi Network',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostOfflineBanner extends StatelessWidget {
  const _HostOfflineBanner();

  @override
  Widget build(BuildContext context) {
    final pwa = WebPwaService.instance;

    return AnimatedBuilder(
      animation: pwa,
      builder: (context, _) {
        if (pwa.isHostOnline) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 10,
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF991B1B).withValues(alpha: 0.95),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFEF4444), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Host Offline — Waiting for Connection',
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Make sure your Laptop or Phone is open on the same Wi-Fi.',
                            style: tt.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_ethernet_rounded,
                          color: Colors.white, size: 20),
                      tooltip: 'Change Host IP',
                      onPressed: () => _showChangeHostDialog(context, pwa),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangeHostDialog(BuildContext context, WebPwaService pwa) {
    final controller = TextEditingController(text: pwa.hostUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Change Host IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If your host device IP changed (e.g. switching from Laptop to Phone), enter the new address below:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'http://192.168.1.147:8080',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              pwa.setCustomHostUrl(controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Connect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
