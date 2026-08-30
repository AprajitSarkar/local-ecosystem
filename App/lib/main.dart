// lib/main.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'application/pending_share_service.dart';
import 'application/settings_service.dart';
import 'application/silent_sender_cli.dart';
import 'application/web_portal_server.dart';
import 'core/logging/crash_reporting_service.dart';
import 'core/web/web_pwa_service.dart';
import 'data/security/device_identity.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // If invoked with --send from Windows Explorer context menu, send headlessly without opening GUI
  if (!kIsWeb && args.isNotEmpty) {
    if (args.contains('--send')) {
      final targets = args.where((a) => a != '--send' && !a.startsWith('--')).toList();
      if (targets.isNotEmpty) {
        await executeSilentBackgroundSend(targets);
        exit(0);
      }
    }
    PendingShareService.instance.handleArgs(args);
  }

  // Bootstrap order matters:
  // 1. Crash Reporting (capture all startup and runtime errors)
  await CrashReportingService.instance.init();
  // 2. Settings (used by identity display name)
  await SettingsService.instance.init();
  // 3. Device identity (generates key pair if first run)
  await DeviceIdentityService.instance.getOrCreate();
  // 4. Start Embedded LAN Web Portal Server (serves Web UI for iPad/Browsers on LAN)
  try {
    await WebPortalServer.instance.start();
  } catch (_) {}
  // 5. Initialize Web PWA Services (Heartbeat, Host monitoring, Permissions)
  WebPwaService.instance.init();

  runApp(
    const ProviderScope(
      child: LocalEcosystemApp(),
    ),
  );
}
