import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a connection to the IndexedDB database (Web platform)
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'bamboo_mapper_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return db.resolvedExecutor;
  });
}
