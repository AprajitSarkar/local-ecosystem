import 'package:drift/drift.dart';
import 'connection/connection.dart' as conn;

part 'database.g.dart';

// ─── Tables ──────────────────────────────────────────────────────────────────

class EcosystemTable extends Table {
  @override
  String get tableName => 'ecosystems';

  TextColumn get ecosystemId => text()();
  TextColumn get name => text()();
  TextColumn get ownerDeviceId => text()();
  IntColumn get protocolVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {ecosystemId};
}

class DeviceTable extends Table {
  @override
  String get tableName => 'devices';

  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get platform => text()();
  TextColumn get publicKey => text()();
  TextColumn get capabilities => text().withDefault(const Constant('[]'))();
  TextColumn get trustStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastSeen => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

class TransferTable extends Table {
  @override
  String get tableName => 'transfers';

  TextColumn get transferId => text()();
  TextColumn get filename => text()();
  TextColumn get mimeType => text()();
  IntColumn get totalBytes => integer()();
  TextColumn get direction => text()();
  TextColumn get peerDeviceId => text()();
  TextColumn get peerDeviceName => text()();
  TextColumn get state => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {transferId};
}

class ClipboardEventTable extends Table {
  @override
  String get tableName => 'clipboard_events';

  TextColumn get eventId => text()();
  TextColumn get sourceDeviceId => text()();
  TextColumn get sourceDeviceName => text()();
  TextColumn get textPreview => text()();
  TextColumn get payloadHash => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isLocal => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {eventId};
}

class ActivityTable extends Table {
  @override
  String get tableName => 'activity';

  TextColumn get entryId => text()();
  TextColumn get type => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get description => text()();
  TextColumn get peerDeviceName => text().nullable()();
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {entryId};
}

class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  EcosystemTable,
  DeviceTable,
  TransferTable,
  ClipboardEventTable,
  ActivityTable,
  SettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
