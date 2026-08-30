// lib/data/local/daos/settings_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> get(String key) async {
    final row = await (select(settingsTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) =>
      into(settingsTable).insertOnConflictUpdate(
        SettingsTableCompanion(key: Value(key), value: Value(value)),
      );

  Future<void> remove(String key) =>
      (delete(settingsTable)..where((t) => t.key.equals(key))).go();
}
