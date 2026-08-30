// lib/data/local/daos/device_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';

part 'device_dao.g.dart';

@DriftAccessor(tables: [DeviceTable])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.db);

  Future<List<DeviceTableData>> getAllDevices() => select(deviceTable).get();

  Stream<List<DeviceTableData>> watchAllDevices() => select(deviceTable).watch();

  Future<DeviceTableData?> getDevice(String deviceId) =>
      (select(deviceTable)..where((t) => t.deviceId.equals(deviceId)))
          .getSingleOrNull();

  Future<void> upsertDevice(DeviceTableCompanion device) =>
      into(deviceTable).insertOnConflictUpdate(device);

  Future<void> updateTrustStatus(String deviceId, String trustStatus) =>
      (update(deviceTable)..where((t) => t.deviceId.equals(deviceId)))
          .write(DeviceTableCompanion(trustStatus: Value(trustStatus)));

  Future<void> updateLastSeen(String deviceId, DateTime lastSeen) =>
      (update(deviceTable)..where((t) => t.deviceId.equals(deviceId)))
          .write(DeviceTableCompanion(lastSeen: Value(lastSeen)));

  Future<void> deleteDevice(String deviceId) =>
      (delete(deviceTable)..where((t) => t.deviceId.equals(deviceId))).go();
}
