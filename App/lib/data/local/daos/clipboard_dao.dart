// lib/data/local/daos/clipboard_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';

part 'clipboard_dao.g.dart';

@DriftAccessor(tables: [ClipboardEventTable])
class ClipboardDao extends DatabaseAccessor<AppDatabase>
    with _$ClipboardDaoMixin {
  ClipboardDao(super.db);

  Stream<ClipboardEventTableData?> watchLatestEvent() =>
      (select(clipboardEventTable)
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .watchSingleOrNull();

  Future<bool> hasEvent(String eventId) async {
    final row = await (select(clipboardEventTable)
          ..where((t) => t.eventId.equals(eventId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> insertEvent(ClipboardEventTableCompanion event) =>
      into(clipboardEventTable).insertOnConflictUpdate(event);

  /// Keep only the most recent N events to avoid unbounded growth.
  Future<void> pruneOldEvents({int keep = 50}) async {
    final all = await (select(clipboardEventTable)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();
    if (all.length > keep) {
      final toDelete = all.sublist(keep);
      for (final row in toDelete) {
        await (delete(clipboardEventTable)
              ..where((t) => t.eventId.equals(row.eventId)))
            .go();
      }
    }
  }
}
