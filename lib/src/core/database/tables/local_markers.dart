import 'package:drift/drift.dart';

/// Sync status enumeration for tracking local changes
class SyncStatus {
  static const String synced = 'synced';
  static const String pendingCreate = 'pending_create';
  static const String pendingUpdate = 'pending_update';
  static const String pendingDelete = 'pending_delete';
}

/// Local markers table - mirrors server markers with sync tracking fields
class LocalMarkers extends Table {
  /// Primary key - UUID (local or server)
  TextColumn get id => text()();

  /// Server-generated short code (null if pending create)
  TextColumn get shortCode => text().nullable()();

  /// Creator user ID (foreign key to local_users)
  TextColumn get creatorId => text()();

  /// Marker name
  TextColumn get name => text()();

  /// Optional description
  TextColumn get description => text().nullable()();

  /// Bamboo species/strain
  TextColumn get strain => text().nullable()();

  /// Count of bamboo
  IntColumn get quantity => integer().nullable()();

  /// GPS latitude coordinate
  RealColumn get latitude => real()();

  /// GPS longitude coordinate
  RealColumn get longitude => real()();

  /// Server image URL
  TextColumn get imageUrl => text().nullable()();

  /// Local file path for offline image (pending upload or cached)
  TextColumn get localImagePath => text().nullable()();

  /// Land owner name
  TextColumn get ownerName => text().nullable()();

  /// Owner contact information
  TextColumn get ownerContact => text().nullable()();

  /// Record creation timestamp (Unix milliseconds)
  IntColumn get createdAt => integer()();

  /// Record update timestamp (Unix milliseconds)
  IntColumn get updatedAt => integer()();

  // ============ Sync Tracking Fields ============

  /// Sync status: synced, pending_create, pending_update, pending_delete
  TextColumn get syncStatus =>
      text().withDefault(const Constant(SyncStatus.synced))();

  /// Original local UUID (for tracking after server assigns ID)
  TextColumn get localId => text().nullable()();

  /// Server UUID (null if not yet synced)
  TextColumn get serverId => text().nullable()();

  /// Last successful sync timestamp (Unix milliseconds)
  IntColumn get lastSyncedAt => integer().nullable()();

  /// Soft delete flag (0 = active, 1 = deleted)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
