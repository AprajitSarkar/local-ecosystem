import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../application/clipboard_sync_service.dart';
import '../application/discovery_service.dart';
import '../application/media_control_service.dart';
import '../application/notification_mirror_service.dart';
import '../application/pairing_service.dart';
import '../application/pending_share_service.dart';
import '../application/power_management_service.dart';
import '../application/remote_input_service.dart';
import '../application/settings_service.dart';
import '../application/transfer_service.dart';
import '../core/audio/sound_effect_service.dart';
import '../core/web/web_pwa_service.dart';
import '../domain/entities/transfer.dart';
import '../features/devices/presentation/devices_screen.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class LocalEcosystemApp extends ConsumerStatefulWidget {
  const LocalEcosystemApp({super.key});

  @override
  ConsumerState<LocalEcosystemApp> createState() => _LocalEcosystemAppState();
}

class _LocalEcosystemAppState extends ConsumerState<LocalEcosystemApp> {
  StreamSubscription<IncomingPairingRequest>? _pairingSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb && Platform.isAndroid) {
        Future.microtask(() async {
          try {
            await Permission.notification.request();
            await Permission.nearbyWifiDevices.request();
            if (await Permission.storage.isDenied) {
              await Permission.storage.request();
            }
          } catch (_) {}
        });
      }

      ref.read(discoveryServiceProvider.notifier).start();
      ref.read(transferServiceProvider); // Eagerly initialize and wire to WebPortalServer
      ClipboardSyncService.instance.clipboardDao =
          ref.read(clipboardDaoProvider);
      ClipboardSyncService.instance.activityDao =
          ref.read(activityDaoProvider);
      ClipboardSyncService.instance.start(null);

      NotificationMirrorService.instance.activityDao =
          ref.read(activityDaoProvider);
      NotificationMirrorService.instance.init();
      RemoteInputService.instance.init();
      MediaControlService.instance.init();
      PowerManagementService.instance.init();

      if (PendingShareService.instance.initialSharePaths.isNotEmpty) {
        appRouter.go('/transfers');
      }

      // Listen for incoming pairing requests globally (native TCP sockets & web HTTP requests)
      _pairingSub = ref.read(pairingServiceProvider).incomingRequests.listen((req) {
        SoundEffectService.instance.playRequestAlert();
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null) {
          showModalBottomSheet(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Theme.of(ctx).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => PairingRequestSheet(request: req),
          );
        }
      });

      if (kIsWeb) {
        WebPwaService.instance.onPendingPairingReceived = (data) {
          SoundEffectService.instance.playRequestAlert();
          final ctx = rootNavigatorKey.currentContext;
          if (ctx == null) return;
          final hostName = data['hostName'] as String? ?? 'Host Device';
          final ecoName = data['ecosystemName'] as String? ?? "Local Ecosystem";
          final ecoId = data['ecosystemId'] as String? ?? '';
          final reqId = data['requestId'] as String? ?? '';

          showModalBottomSheet(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Theme.of(ctx).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (sheetCtx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(sheetCtx).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Icon(Icons.hub_rounded, size: 56, color: AppColors.accent),
                    const SizedBox(height: AppSpacing.base),
                    Text('Join Ecosystem Request',
                        style: Theme.of(sheetCtx).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    Text('"$hostName" wants to add this iPad to "$ecoName"',
                        style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(color: AppColors.accent),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              WebPwaService.instance.respondToPairing(requestId: reqId, approved: false);
                              Navigator.pop(sheetCtx);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              await WebPwaService.instance.respondToPairing(requestId: reqId, approved: true);
                              await SettingsService.instance.saveAndActivateEcosystem(id: ecoId, name: ecoName);
                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Joined "$ecoName"!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                appRouter.go('/home');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: const Text('Accept & Join'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        };

        WebPwaService.instance.onPendingDownloadReceived = (item) {
          SoundEffectService.instance.playCompletionAlert();
          final filename = item['filename'] as String? ?? 'file';
          final totalBytes = item['totalBytes'] as int? ?? 0;
          final downloadUrl = '${WebPwaService.instance.hostUrl}${item['downloadUrl']}';
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                ),
                duration: const Duration(seconds: 12),
                content: Row(
                  children: [
                    const Icon(Icons.download_done_rounded, color: AppColors.success, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📥 File Received: $filename',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB • Tap to save to device',
                              style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: 'Save File',
                  textColor: AppColors.accent,
                  onPressed: () => WebPwaService.instance.triggerBrowserDownloadFromUrl(downloadUrl, filename),
                ),
              ),
            );
          }
        };
      }
    });
  }

  @override
  void dispose() {
    _pairingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Local Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
