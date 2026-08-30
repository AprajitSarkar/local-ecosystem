// lib/data/local/daos/ecosystem_dao.dart

import 'package:drift/drift.dart';
import '../database.dart';

part 'ecosystem_dao.g.dart';

@DriftAccessor(tables: [EcosystemTable])
class EcosystemDao extends DatabaseAccessor<AppDatabase>
    with _$EcosystemDaoMixin {
  EcosystemDao(super.db);

  Future<EcosystemTableData?> getEcosystem() =>
      select(ecosystemTable).getSingleOrNull();

  Stream<EcosystemTableData?> watchEcosystem() =>
      select(ecosystemTable).watchSingleOrNull();

  Future<void> upsertEcosystem(EcosystemTableCompanion eco) =>
      into(ecosystemTable).insertOnConflictUpdate(eco);

  Future<void> deleteEcosystem() => delete(ecosystemTable).go();

  Future<void> updateName(String name) =>
      update(ecosystemTable).write(EcosystemTableCompanion(name: Value(name)));
}
