import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/local_markers.dart';
import 'tables/local_users.dart';
import 'tables/sync_queue.dart';
import 'tables/sync_metadata.dart';

part 'app_database.g.dart';

/// Main application database using Drift (SQLite)
@DriftDatabase(tables: [LocalMarkers, LocalUsers, SyncQueue, SyncMetadata])
class AppDatabase extends _$AppDatabase {
  /// Singleton instance
  static AppDatabase? _instance;

  /// Private constructor
  AppDatabase._() : super(_openConnection());

  /// Get singleton instance
  factory AppDatabase() {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Database schema version
  @override
  int get schemaVersion => 1;

  /// Migration strategy for schema upgrades
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations here
      },
    );
  }

  // ============ Marker Operations ============

  /// Get all non-deleted markers
  Future<List<LocalMarker>> getAllMarkers() {
    return (select(localMarkers)..where((m) => m.isDeleted.equals(false)))
        .get();
  }

  /// Get marker by ID
  Future<LocalMarker?> getMarkerById(String id) {
    return (select(localMarkers)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get markers by sync status
  Future<List<LocalMarker>> getMarkersBySyncStatus(String status) {
    return (select(localMarkers)..where((m) => m.syncStatus.equals(status)))
        .get();
  }

  /// Insert or update marker
  Future<void> upsertMarker(LocalMarkersCompanion marker) {
    return into(localMarkers).insertOnConflictUpdate(marker);
  }

  /// Update marker sync status
  Future<void> updateMarkerSyncStatus(String id, String status) {
    return (update(localMarkers)..where((m) => m.id.equals(id)))
        .write(LocalMarkersCompanion(syncStatus: Value(status)));
  }

  /// Soft delete marker
  Future<void> softDeleteMarker(String id) {
    return (update(localMarkers)..where((m) => m.id.equals(id))).write(
      LocalMarkersCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value(SyncStatus.pendingDelete),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Hard delete marker
  Future<void> hardDeleteMarker(String id) {
    return (delete(localMarkers)..where((m) => m.id.equals(id))).go();
  }

  /// Delete all markers
  Future<void> deleteAllMarkers() {
    return delete(localMarkers).go();
  }

  // ============ User Operations ============

  /// Get user by ID
  Future<LocalUser?> getUserById(String id) {
    return (select(localUsers)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Insert or update user
  Future<void> upsertUser(LocalUsersCompanion user) {
    return into(localUsers).insertOnConflictUpdate(user);
  }

  /// Delete all users
  Future<void> deleteAllUsers() {
    return delete(localUsers).go();
  }

  // ============ Sync Queue Operations ============

  /// Get all pending sync queue items
  Future<List<SyncQueueData>> getPendingSyncItems() {
    return (select(syncQueue)
          ..where((q) => q.status.equals(QueueStatus.pending))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Get sync queue items by entity ID
  Future<List<SyncQueueData>> getSyncItemsByEntityId(String entityId) {
    return (select(syncQueue)..where((q) => q.entityId.equals(entityId))).get();
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue(SyncQueueCompanion item) {
    return into(syncQueue).insert(item);
  }

  /// Update sync queue item status
  Future<void> updateSyncQueueStatus(String id, String status,
      {String? error}) {
    return (update(syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion(
        status: Value(status),
        lastError: Value(error),
        retryCount: error != null
            ? const Value.absent() // Will be incremented separately
            : const Value.absent(),
      ),
    );
  }

  /// Increment retry count for sync queue item
  Future<void> incrementRetryCount(String id) async {
    final item =
        await (select(syncQueue)..where((q) => q.id.equals(id))).getSingle();
    await (update(syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion(retryCount: Value(item.retryCount + 1)),
    );
  }

  /// Delete sync queue item
  Future<void> deleteSyncQueueItem(String id) {
    return (delete(syncQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Delete sync queue items by entity ID
  Future<void> deleteSyncQueueByEntityId(String entityId) {
    return (delete(syncQueue)..where((q) => q.entityId.equals(entityId))).go();
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    final count = await (select(syncQueue)
          ..where((q) => q.status.isIn([QueueStatus.pending, QueueStatus.failed])))
        .get();
    return count.length;
  }

  /// Clear all completed sync items
  Future<void> clearCompletedSyncItems() {
    return (delete(syncQueue)..where((q) => q.status.equals(QueueStatus.completed)))
        .go();
  }

  // ============ Sync Metadata Operations ============

  /// Get metadata value by key
  Future<String?> getMetadata(String key) async {
    final result =
        await (select(syncMetadata)..where((m) => m.key.equals(key)))
            .getSingleOrNull();
    return result?.value;
  }

  /// Set metadata value
  Future<void> setMetadata(String key, String value) {
    return into(syncMetadata).insertOnConflictUpdate(
      SyncMetadataCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Delete metadata
  Future<void> deleteMetadata(String key) {
    return (delete(syncMetadata)..where((m) => m.key.equals(key))).go();
  }

  // ============ Utility Methods ============

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    await deleteAllMarkers();
    await deleteAllUsers();
    await delete(syncQueue).go();
    await delete(syncMetadata).go();
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    await close();
    _instance = null;
  }
}

/// Opens a connection to the SQLite database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bamboo_mapper.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
