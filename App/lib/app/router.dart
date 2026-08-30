import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../application/settings_service.dart';
import '../features/onboarding/presentation/permissions_setup_screen.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/onboarding/presentation/create_ecosystem_screen.dart';
import '../features/onboarding/presentation/join_ecosystem_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/devices/presentation/devices_screen.dart';
import '../features/devices/presentation/device_detail_screen.dart';
import '../features/transfers/presentation/transfers_screen.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/receive_folder_screen.dart';
import '../features/settings/presentation/crash_logs_screen.dart';
import 'app.dart';
import 'shell_scaffold.dart';

final _isMobileNative = !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: (!_isMobileNative) ||
          SettingsService.instance.hasCompletedPermissions
      ? (SettingsService.instance.hasActiveEcosystem ? '/home' : '/welcome')
      : '/permissions',
  routes: [
    GoRoute(
      path: '/permissions',
      builder: (ctx, state) => const PermissionsSetupScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (ctx, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/create-ecosystem',
      builder: (ctx, state) => const CreateEcosystemScreen(),
    ),
    GoRoute(
      path: '/join-ecosystem',
      builder: (ctx, state) => const JoinEcosystemScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, navigationShell) =>
          ShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (ctx, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/devices',
              builder: (ctx, state) => const DevicesScreen(),
              routes: [
                GoRoute(
                  path: ':deviceId',
                  builder: (ctx, state) => DeviceDetailScreen(
                    deviceId: state.pathParameters['deviceId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transfers',
              builder: (ctx, state) => const TransfersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (ctx, state) => const ActivityScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (ctx, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'receive-folder',
                  builder: (ctx, state) => const ReceiveFolderScreen(),
                ),
                GoRoute(
                  path: 'crash-logs',
                  builder: (ctx, state) => const CrashLogsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
