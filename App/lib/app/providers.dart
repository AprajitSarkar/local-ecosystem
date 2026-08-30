// lib/app/providers.dart
// Central Riverpod providers for all application services.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/discovery_service.dart';
import '../application/pairing_service.dart';
import '../application/settings_service.dart';
import '../application/transfer_service.dart';
import '../application/web_portal_server.dart';
import '../domain/entities/transfer.dart';
import '../data/local/database.dart';
import '../data/local/daos/activity_dao.dart';
import '../data/local/daos/clipboard_dao.dart';
import '../data/local/daos/device_dao.dart';
import '../data/local/daos/ecosystem_dao.dart';
import '../data/local/daos/settings_dao.dart';
import '../data/local/daos/transfer_dao.dart';
import '../data/security/device_identity.dart';

// ── Database ──────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAOs ──────────────────────────────────────────────────────────────────────

final deviceDaoProvider = Provider<DeviceDao>((ref) {
  return DeviceDao(ref.watch(databaseProvider));
});

final ecosystemDaoProvider = Provider<EcosystemDao>((ref) {
  return EcosystemDao(ref.watch(databaseProvider));
});

final transferDaoProvider = Provider<TransferDao>((ref) {
  return TransferDao(ref.watch(databaseProvider));
});

final activityDaoProvider = Provider<ActivityDao>((ref) {
  return ActivityDao(ref.watch(databaseProvider));
});

final clipboardDaoProvider = Provider<ClipboardDao>((ref) {
  return ClipboardDao(ref.watch(databaseProvider));
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(databaseProvider));
});

// ── Streams ───────────────────────────────────────────────────────────────────

final devicesStreamProvider = StreamProvider((ref) {
  return ref.watch(deviceDaoProvider).watchAllDevices();
});

final activityStreamProvider = StreamProvider((ref) {
  return ref.watch(activityDaoProvider).watchActivity();
});

final latestClipboardProvider = StreamProvider((ref) {
  return ref.watch(clipboardDaoProvider).watchLatestEvent();
});

final recentTransfersProvider = StreamProvider((ref) {
  return ref.watch(transferDaoProvider).watchRecentTransfers();
});

// ── Device identity ───────────────────────────────────────────────────────────

final deviceIdentityProvider = FutureProvider((ref) async {
  return DeviceIdentityService.instance.getOrCreate();
});

// ── Pairing ───────────────────────────────────────────────────────────────────

final pairingServiceProvider = Provider<PairingService>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(deviceDaoProvider);
  final service = PairingService(db: db, deviceDao: dao);
  ref.onDispose(service.dispose);
  return service;
});

// ── Transfer ──────────────────────────────────────────────────────────────────

final transferServiceProvider = Provider<TransferService>((ref) {
  final service = TransferService(
    settingsService: SettingsService.instance,
    myDeviceId: DeviceIdentityService.instance.currentDeviceId,
    myDeviceName: SettingsService.instance.deviceName,
    transferDao: ref.watch(transferDaoProvider),
    activityDao: ref.watch(activityDaoProvider),
  );
  WebPortalServer.instance.transferService = service;
  ref.onDispose(service.dispose);
  return service;
});

final activeTransfersProvider = StreamProvider<List<Transfer>>((ref) {
  final service = ref.watch(transferServiceProvider);
  return service.transferUpdates.map((_) => service.activeTransfers);
});

// ── Connection & Online Status ───────────────────────────────────────────────

final connectionStatusProvider = Provider<Map<String, bool>>((ref) {
  final discoveredPeers = ref.watch(discoveryServiceProvider);
  final onlineMap = <String, bool>{};
  for (final p in discoveredPeers) {
    if (p.isOnline) {
      onlineMap[p.peer.deviceId] = true;
    }
  }
  return onlineMap;
});
