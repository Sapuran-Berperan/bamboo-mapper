import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/network/network_monitor.dart';
import '../../core/sync/sync_service.dart' show SyncService, SyncResult;
import '../../data/datasources/marker_local_datasource.dart';
import '../../data/datasources/marker_remote_datasource.dart';
import '../entities/e_marker.dart';
import '../repositories/r_marker.dart';

/// Offline-first implementation of marker repository
/// - Reads from local database first
/// - Writes to local database immediately (optimistic updates)
/// - Queues operations for sync with server
class InfrastructureMarkerOffline implements RepositoryPolygon {
  final _localDataSource = MarkerLocalDataSource.instance;
  final _remoteDataSource = MarkerRemoteDataSource.instance;
  final _networkMonitor = NetworkMonitor.instance;
  final _syncService = SyncService.instance;

  /// Current user ID for creating markers
  String? _currentUserId;

  /// Set the current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  @override
  Future<EntitiesMarker?> createMarker(EntitiesMarker marker) async {
    try {
      // Determine image path
      String? imagePath;
      if (marker.imageUrl.isNotEmpty && !marker.imageUrl.startsWith('http')) {
        final file = File(marker.imageUrl);
        if (await file.exists()) {
          imagePath = marker.imageUrl;
        }
      }

      // Create locally first (offline-first)
      final localMarker = await _localDataSource.createMarker(
        name: marker.name,
        latitude: marker.location.latitude,
        longitude: marker.location.longitude,
        creatorId: _currentUserId ?? marker.creatorId,
        description: marker.description.isEmpty ? null : marker.description,
        strain: marker.strain.isEmpty ? null : marker.strain,
        quantity: marker.quantity == 0 ? null : marker.quantity,
        ownerName: marker.ownerName.isEmpty ? null : marker.ownerName,
        ownerContact: marker.ownerContact.isEmpty ? null : marker.ownerContact,
        imagePath: imagePath,
      );

      debugPrint('[InfrastructureMarkerOffline] Marker created locally: ${localMarker.id}');

      // Trigger sync if online
      if (_networkMonitor.isOnline) {
        _syncService.sync();
      }

      return localMarker;
    } catch (e) {
      debugPrint('[InfrastructureMarkerOffline] Error creating marker: $e');
      rethrow;
    }
  }

  @override
  Future<EntitiesMarker?> readMarker(String id) async {
    try {
      // Try local first
      final localMarker = await _localDataSource.getMarkerById(id);
      if (localMarker != null) {
        return localMarker;
      }

      // If not found locally and online, fetch from server
      if (_networkMonitor.isOnline) {
        try {
          final response = await _remoteDataSource.getMarkerById(id);
          final entity = EntitiesMarker.fromResponse(response);
          // Cache locally
          await _localDataSource.upsertFromServer(entity);
          return entity;
        } catch (e) {
          debugPrint('[InfrastructureMarkerOffline] Error fetching from server: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('[InfrastructureMarkerOffline] Error reading marker: $e');
      rethrow;
    }
  }

  @override
  Future<List<EntitiesMarker>> readListMarker() async {
    try {
      // Always read from local first
      final localMarkers = await _localDataSource.getAllMarkers();

      // If online, sync in background
      if (_networkMonitor.isOnline) {
        // Don't wait for sync, return local data immediately
        _syncService.sync().then((_) {
          // Sync completed
        }).catchError((e) {
          debugPrint('[InfrastructureMarkerOffline] Background sync error: $e');
          return SyncResult(success: false, error: e.toString());
        });
      }

      return localMarkers;
    } catch (e) {
      debugPrint('[InfrastructureMarkerOffline] Error reading marker list: $e');
      return [];
    }
  }

  @override
  Future<EntitiesMarker?> updateMarker(
    EntitiesMarker marker, {
    bool keepExistingImage = false,
  }) async {
    try {
      // Determine image path
      String? imagePath;
      if (!keepExistingImage && marker.imageUrl.isNotEmpty) {
        if (!marker.imageUrl.startsWith('http') &&
            !marker.imageUrl.startsWith('NULL:')) {
          final file = File(marker.imageUrl);
          if (await file.exists()) {
            imagePath = marker.imageUrl;
          }
        }
      }

      // Update locally first
      final updatedMarker = await _localDataSource.updateMarker(
        id: marker.id,
        name: marker.name,
        latitude: marker.location.latitude,
        longitude: marker.location.longitude,
        description: marker.description,
        strain: marker.strain,
        quantity: marker.quantity,
        ownerName: marker.ownerName,
        ownerContact: marker.ownerContact,
        imagePath: imagePath,
      );

      debugPrint('[InfrastructureMarkerOffline] Marker updated locally: ${marker.id}');

      // Trigger sync if online
      if (_networkMonitor.isOnline) {
        _syncService.sync();
      }

      return updatedMarker;
    } catch (e) {
      debugPrint('[InfrastructureMarkerOffline] Error updating marker: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMarker(EntitiesMarker marker) async {
    try {
      // Delete locally (will queue for sync if needed)
      await _localDataSource.deleteMarker(marker.id);

      debugPrint('[InfrastructureMarkerOffline] Marker deleted locally: ${marker.id}');

      // Trigger sync if online
      if (_networkMonitor.isOnline) {
        _syncService.sync();
      }
    } catch (e) {
      debugPrint('[InfrastructureMarkerOffline] Error deleting marker: $e');
      rethrow;
    }
  }

  // ============ Image Operations (delegated to original implementation) ============

  @override
  Future<bool> createImageMarker(String localPath, String storagePath) async {
    // Not used in offline-first approach - images are handled by sync service
    debugPrint('[InfrastructureMarkerOffline] createImageMarker not used in offline mode');
    return true;
  }

  @override
  Future<bool> updateImageMarker(
      String localPath, String storagePath, String oldImageUrl) async {
    // Not used in offline-first approach - images are handled by sync service
    debugPrint('[InfrastructureMarkerOffline] updateImageMarker not used in offline mode');
    return true;
  }

  @override
  Future<void> deteleImageMarker(String url) async {
    // Not used in offline-first approach - images are handled by sync service
    debugPrint('[InfrastructureMarkerOffline] deteleImageMarker not used in offline mode');
  }

  @override
  Future<void> testDeleteImageMarker() async {
    // Not used in offline mode
  }

  // ============ Sync Helper Methods ============

  /// Force a full sync with server
  Future<void> forceSync() async {
    if (_networkMonitor.isOnline) {
      await _syncService.sync();
    }
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _syncService.getPendingSyncCount();
  }

  /// Clear all local data (for logout)
  Future<void> clearLocalData() async {
    await _localDataSource.clearAll();
  }
}
