import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Opens a connection to the IndexedDB database (Web platform)
QueryExecutor openConnection() {
  return WebDatabase.withStorage(
    DriftWebStorage.indexedDb('bamboo_mapper_db'),
    logStatements: false,
  );
}
