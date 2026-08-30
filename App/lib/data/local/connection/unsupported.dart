// lib/data/local/connection/unsupported.dart

import 'package:drift/drift.dart';

QueryExecutor openConnection() {
  throw UnsupportedError('Platform not supported for database storage');
}
