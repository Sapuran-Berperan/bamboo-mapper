import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../domain/entities/e_marker.dart';
import 'package:latlong2/latlong.dart';

/// Local data source for marker operations using SQLite
class MarkerLocalDataSource {
  MarkerLocalDataSource._();
  static final MarkerLocalDataSource instance = MarkerLocalDataSource._();

  final AppDatabase _db = AppDatabase();
  final Uuid _uuid = const Uuid();

  // ============ Read Operations ============

  /// Get all non-deleted markers from local database
  Future<List<EntitiesMarker>> getAllMarkers() async {
    final markers = await _db.getAllMarkers();
    return markers.map(_mapToEntity).toList();
  }

  /// Get marker by ID
  Future<EntitiesMarker?> getMarkerById(String id) async {
    final marker = await _db.getMarkerById(id);
    return marker != null ? _mapToEntity(marker) : null;
  }

  /// Get markers pending sync
  Future<List<EntitiesMarker>> getPendingMarkers() async {
    final pendingCreate =
        await _db.getMarkersBySyncStatus(SyncStatus.pendingCreate);
    final pendingUpdate =
        await _db.getMarkersBySyncStatus(SyncStatus.pendingUpdate);
    final pendingDelete =
        await _db.getMarkersBySyncStatus(SyncStatus.pendingDelete);

    return [
      ...pendingCreate.map(_mapToEntity),
      ...pendingUpdate.map(_mapToEntity),
      ...pendingDelete.map(_mapToEntity),
    ];
  }

  // ============ Create Operations ============

  /// Create a new marker locally (offline-first)
  Future<EntitiesMarker> createMarker({
    required String name,
    required double latitude,
    required double longitude,
    required String creatorId,
    String? description,
    String? strain,
    int? quantity,
    String? ownerName,
    String? ownerContact,
    String? imagePath,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Save image to pending folder if provided
    String? localImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      localImagePath = await _saveImageToPending(localId, imagePath);
    }

    final companion = LocalMarkersCompanion(
      id: Value(localId),
      shortCode: const Value.absent(), // Server will generate
      creatorId: Value(creatorId),
      name: Value(name),
      description: Value(description),
      strain: Value(strain),
      quantity: Value(quantity),
      latitude: Value(latitude),
      longitude: Value(longitude),
      imageUrl: const Value.absent(),
      localImagePath: Value(localImagePath),
      ownerName: Value(ownerName),
      ownerContact: Value(ownerContact),
      createdAt: Value(now),
      updatedAt: Value(now),
      syncStatus: const Value(SyncStatus.pendingCreate),
      localId: Value(localId),
      serverId: const Value.absent(),
      lastSyncedAt: const Value.absent(),
      isDeleted: const Value(false),
    );

    await _db.upsertMarker(companion);

    // Add to sync queue
    await _addToSyncQueue(
      entityId: localId,
      operation: SyncOperation.create,
      payload: {
        'name': name,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'description': description,
        'strain': strain,
        'quantity': quantity,
        'owner_name': ownerName,
        'owner_contact': ownerContact,
      },
      localImagePath: localImagePath,
    );

    return EntitiesMarker(
      id: localId,
      shortCode: '',
      creatorId: creatorId,
      name: name,
      description: description ?? '',
      strain: strain ?? '',
      quantity: quantity ?? 0,
      imageUrl: '',
      ownerName: ownerName ?? '',
      ownerContact: ownerContact ?? '',
      location: LatLng(latitude, longitude),
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  // ============ Update Operations ============

  /// Update an existing marker locally
  Future<EntitiesMarker> updateMarker({
    required String id,
    String? name,
    double? latitude,
    double? longitude,
    String? description,
    String? strain,
    int? quantity,
    String? ownerName,
    String? ownerContact,
    String? imagePath,
  }) async {
    final existing = await _db.getMarkerById(id);
    if (existing == null) {
      throw Exception('Marker tidak ditemukan');
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Handle image update
    String? localImagePath = existing.localImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      localImagePath = await _saveImageToPending(id, imagePath);
    }

    // Determine new sync status
    String newSyncStatus;
    if (existing.syncStatus == SyncStatus.pendingCreate) {
      // Still pending create, keep that status
      newSyncStatus = SyncStatus.pendingCreate;
    } else {
      newSyncStatus = SyncStatus.pendingUpdate;
    }

    final companion = LocalMarkersCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      latitude: Value(latitude ?? existing.latitude),
      longitude: Value(longitude ?? existing.longitude),
      description: Value(description ?? existing.description),
      strain: Value(strain ?? existing.strain),
      quantity: Value(quantity ?? existing.quantity),
      ownerName: Value(ownerName ?? existing.ownerName),
      ownerContact: Value(ownerContact ?? existing.ownerContact),
      localImagePath: Value(localImagePath),
      updatedAt: Value(now),
      syncStatus: Value(newSyncStatus),
    );

    await _db.upsertMarker(companion);

    // Update sync queue
    if (existing.syncStatus == SyncStatus.pendingCreate) {
      // Update existing create queue item
      await _updateSyncQueuePayload(id, {
        'name': name ?? existing.name,
        'latitude': (latitude ?? existing.latitude).toString(),
        'longitude': (longitude ?? existing.longitude).toString(),
        'description': description ?? existing.description,
        'strain': strain ?? existing.strain,
        'quantity': quantity ?? existing.quantity,
        'owner_name': ownerName ?? existing.ownerName,
        'owner_contact': ownerContact ?? existing.ownerContact,
      }, localImagePath);
    } else {
      // Add/update update queue item
      await _db.deleteSyncQueueByEntityId(id);
      await _addToSyncQueue(
        entityId: existing.serverId ?? id,
        operation: SyncOperation.update,
        payload: {
          if (name != null) 'name': name,
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
          if (description != null) 'description': description,
          if (strain != null) 'strain': strain,
          if (quantity != null) 'quantity': quantity,
          if (ownerName != null) 'owner_name': ownerName,
          if (ownerContact != null) 'owner_contact': ownerContact,
        },
        localImagePath: localImagePath,
      );
    }

    final updated = await _db.getMarkerById(id);
    return _mapToEntity(updated!);
  }

  // ============ Delete Operations ============

  /// Delete a marker (soft delete if synced, hard delete if pending)
  Future<void> deleteMarker(String id) async {
    final existing = await _db.getMarkerById(id);
    if (existing == null) {
      throw Exception('Marker tidak ditemukan');
    }

    if (existing.syncStatus == SyncStatus.pendingCreate) {
      // Never synced, just delete locally
      await _db.hardDeleteMarker(id);
      await _db.deleteSyncQueueByEntityId(id);
      await _deleteLocalImage(existing.localImagePath);
    } else {
      // Synced with server, soft delete and queue for sync
      await _db.softDeleteMarker(id);

      // Remove any pending update operations
      await _db.deleteSyncQueueByEntityId(id);

      // Add delete operation to queue
      await _addToSyncQueue(
        entityId: existing.serverId ?? id,
        operation: SyncOperation.delete,
        payload: {},
      );
    }
  }

  // ============ Sync Helper Methods ============

  /// Update marker after successful server sync
  Future<void> updateMarkerAfterSync({
    required String localId,
    required String serverId,
    required String shortCode,
    String? imageUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final existingMarker = await _db.getMarkerById(localId);
    if (existingMarker != null) {
      await _db.upsertMarker(LocalMarkersCompanion(
        id: Value(localId),
        serverId: Value(serverId),
        shortCode: Value(shortCode),
        imageUrl: Value(imageUrl),
        syncStatus: const Value(SyncStatus.synced),
        lastSyncedAt: Value(now),
      ));
    }

    // Move image from pending to cached if exists
    final marker = await _db.getMarkerById(localId);
    if (marker?.localImagePath != null && imageUrl != null) {
      await _moveImageToCached(marker!.localImagePath!, serverId);
    }
  }

  /// Insert or update marker from server data
  Future<void> upsertFromServer(EntitiesMarker marker) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = LocalMarkersCompanion(
      id: Value(marker.id),
      shortCode: Value(marker.shortCode),
      creatorId: Value(marker.creatorId),
      name: Value(marker.name),
      description: Value(marker.description),
      strain: Value(marker.strain),
      quantity: Value(marker.quantity),
      latitude: Value(marker.location.latitude),
      longitude: Value(marker.location.longitude),
      imageUrl: Value(marker.imageUrl),
      ownerName: Value(marker.ownerName),
      ownerContact: Value(marker.ownerContact),
      createdAt: Value(marker.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(marker.updatedAt.millisecondsSinceEpoch),
      syncStatus: const Value(SyncStatus.synced),
      serverId: Value(marker.id),
      lastSyncedAt: Value(now),
      isDeleted: const Value(false),
    );

    await _db.upsertMarker(companion);
  }

  /// Remove markers deleted on server
  Future<void> removeDeletedFromServer(List<String> serverIds) async {
    final allMarkers = await _db.getAllMarkers();
    for (final marker in allMarkers) {
      if (marker.serverId != null &&
          !serverIds.contains(marker.serverId) &&
          marker.syncStatus == SyncStatus.synced) {
        await _db.hardDeleteMarker(marker.id);
      }
    }
  }

  /// Clear all local markers
  Future<void> clearAll() async {
    await _db.deleteAllMarkers();
  }

  // ============ Private Helper Methods ============

  /// Map database row to entity
  EntitiesMarker _mapToEntity(LocalMarker marker) {
    return EntitiesMarker(
      id: marker.id,
      shortCode: marker.shortCode ?? '',
      creatorId: marker.creatorId,
      name: marker.name,
      description: marker.description ?? '',
      strain: marker.strain ?? '',
      quantity: marker.quantity ?? 0,
      imageUrl: marker.imageUrl ?? marker.localImagePath ?? '',
      ownerName: marker.ownerName ?? '',
      ownerContact: marker.ownerContact ?? '',
      location: LatLng(marker.latitude, marker.longitude),
      createdAt: DateTime.fromMillisecondsSinceEpoch(marker.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(marker.updatedAt),
    );
  }

  /// Add item to sync queue
  Future<void> _addToSyncQueue({
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    String? localImagePath,
  }) async {
    final queueItem = SyncQueueCompanion(
      id: Value(_uuid.v4()),
      entityType: const Value('marker'),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(jsonEncode(payload)),
      localImagePath: Value(localImagePath),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      status: const Value(QueueStatus.pending),
    );

    await _db.addToSyncQueue(queueItem);
  }

  /// Update sync queue payload
  Future<void> _updateSyncQueuePayload(
    String entityId,
    Map<String, dynamic> payload,
    String? localImagePath,
  ) async {
    final items = await _db.getSyncItemsByEntityId(entityId);
    if (items.isNotEmpty) {
      final item = items.first;
      await _db.deleteSyncQueueItem(item.id);
      await _addToSyncQueue(
        entityId: entityId,
        operation: item.operation,
        payload: payload,
        localImagePath: localImagePath,
      );
    }
  }

  /// Save image to pending folder
  Future<String?> _saveImageToPending(String markerId, String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final pendingDir = Directory(p.join(appDir.path, 'images', 'pending'));
      if (!await pendingDir.exists()) {
        await pendingDir.create(recursive: true);
      }

      final extension = p.extension(sourcePath);
      final destPath = p.join(pendingDir.path, '$markerId$extension');
      await sourceFile.copy(destPath);

      return destPath;
    } catch (e) {
      return null;
    }
  }

  /// Move image from pending to cached folder
  Future<void> _moveImageToCached(String pendingPath, String serverId) async {
    try {
      final sourceFile = File(pendingPath);
      if (!await sourceFile.exists()) return;

      final appDir = await getApplicationDocumentsDirectory();
      final cachedDir = Directory(p.join(appDir.path, 'images', 'cached'));
      if (!await cachedDir.exists()) {
        await cachedDir.create(recursive: true);
      }

      final extension = p.extension(pendingPath);
      final destPath = p.join(cachedDir.path, '$serverId$extension');
      await sourceFile.copy(destPath);
      await sourceFile.delete();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Delete local image file
  Future<void> _deleteLocalImage(String? imagePath) async {
    if (imagePath == null) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
