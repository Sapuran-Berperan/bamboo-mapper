import 'package:drift/drift.dart';

/// Metadata keys for sync state
class SyncMetadataKeys {
  static const String lastFullSync = 'last_full_sync';
  static const String lastMarkersSync = 'last_markers_sync';
  static const String syncInProgress = 'sync_in_progress';
  static const String pendingCount = 'pending_count';
}

/// Sync metadata table - key-value store for sync state
class SyncMetadata extends Table {
  /// Primary key - metadata key name
  TextColumn get key => text()();

  /// Metadata value (stored as string)
  TextColumn get value => text()();

  /// Last updated timestamp (Unix milliseconds)
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}
