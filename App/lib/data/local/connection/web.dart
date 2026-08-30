// lib/data/local/connection/web.dart

import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    try {
      final wasmDb = await WasmDatabase.open(
        databaseName: 'local_ecosystem',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return wasmDb.resolvedExecutor;
    } catch (_) {
      try {
        return WebDatabase.withStorage(
          DriftWebStorage.indexedDb('local_ecosystem'),
          logStatements: false,
        );
      } catch (_) {
        return WebDatabase.withStorage(
          DriftWebStorage.volatile(),
          logStatements: false,
        );
      }
    }
  });
}
