import 'package:drift/drift.dart';

/// Operation types for sync queue
class SyncOperation {
  static const String create = 'CREATE';
  static const String update = 'UPDATE';
  static const String delete = 'DELETE';
}

/// Queue status for tracking sync progress
class QueueStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String failed = 'failed';
  static const String completed = 'completed';
}

/// Sync queue table - pending operations to be synced with server
class SyncQueue extends Table {
  /// Primary key - UUID
  TextColumn get id => text()();

  /// Entity type (e.g., 'marker')
  TextColumn get entityType => text()();

  /// Local entity ID
  TextColumn get entityId => text()();

  /// Operation type: CREATE, UPDATE, DELETE
  TextColumn get operation => text()();

  /// JSON serialized payload data
  TextColumn get payload => text()();

  /// Local image path for upload (if applicable)
  TextColumn get localImagePath => text().nullable()();

  /// Queue timestamp (Unix milliseconds)
  IntColumn get createdAt => integer()();

  /// Number of sync attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last error message (if failed)
  TextColumn get lastError => text().nullable()();

  /// Queue status: pending, in_progress, failed, completed
  TextColumn get status =>
      text().withDefault(const Constant(QueueStatus.pending))();

  @override
  Set<Column> get primaryKey => {id};
}
