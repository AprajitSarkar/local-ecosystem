// lib/data/local/daos/transfer_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';

part 'transfer_dao.g.dart';

@DriftAccessor(tables: [TransferTable])
class TransferDao extends DatabaseAccessor<AppDatabase>
    with _$TransferDaoMixin {
  TransferDao(super.db);

  Stream<List<TransferTableData>> watchRecentTransfers({int limit = 50}) =>
      (select(transferTable)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
            ..limit(limit))
          .watch();

  Future<void> insertTransfer(TransferTableCompanion transfer) =>
      into(transferTable).insertOnConflictUpdate(transfer);

  Future<void> updateTransferState({
    required String transferId,
    required String state,
    String? localPath,
    DateTime? completedAt,
    String? errorMessage,
  }) =>
      (update(transferTable)
            ..where((t) => t.transferId.equals(transferId)))
          .write(TransferTableCompanion(
        state: Value(state),
        localPath: localPath != null ? Value(localPath) : const Value.absent(),
        completedAt:
            completedAt != null ? Value(completedAt) : const Value.absent(),
        errorMessage: errorMessage != null
            ? Value(errorMessage)
            : const Value.absent(),
      ));
}
