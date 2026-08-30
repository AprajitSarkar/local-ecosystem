// lib/data/local/daos/activity_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';

part 'activity_dao.g.dart';

@DriftAccessor(tables: [ActivityTable])
class ActivityDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityDaoMixin {
  ActivityDao(super.db);

  Stream<List<ActivityTableData>> watchActivity({int limit = 100}) =>
      (select(activityTable)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .watch();

  Future<void> insertActivity(ActivityTableCompanion entry) =>
      into(activityTable).insert(entry);

  Future<void> clearActivity() => delete(activityTable).go();
}
