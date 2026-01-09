import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../network/network_monitor.dart';
import '../../data/datasources/marker_local_datasource.dart';
import '../../data/datasources/marker_remote_datasource.dart';
import '../../domain/entities/e_marker.dart';

/// Sync status for tracking sync progress
enum SyncState {
  idle,
  syncing,
  success,
  error,
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final String? error;

  SyncResult({
    required this.success,
    this.pushed = 0,
    this.pulled = 0,
    this.error,
  });

  @override
  String toString() =>
      'SyncResult(success: $success, pushed: $pushed, pulled: $pulled, error: $error)';
}

/// Service for synchronizing local data with remote server
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final AppDatabase _db = AppDatabase();
  final NetworkMonitor _networkMonitor = NetworkMonitor.instance;
  final MarkerLocalDataSource _localDataSource = MarkerLocalDataSource.instance;
  final MarkerRemoteDataSource _remoteDataSource =
      MarkerRemoteDataSource.instance;

  /// Stream controller for sync state changes
  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  /// Stream controller for sync results
  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();

  /// Current sync state
  SyncState _currentState = SyncState.idle;

  /// Whether a sync is currently in progress
  bool _isSyncing = false;

  /// Maximum retry count for failed operations
  static const int _maxRetries = 3;

  /// Stream of sync state changes
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Stream of sync results
  Stream<SyncResult> get resultStream => _resultController.stream;

  /// Current sync state
  SyncState get currentState => _currentState;

  /// Whether sync is in progress
  bool get isSyncing => _isSyncing;

  /// Perform a full sync (push then pull)
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Sync already in progress, skipping');
      return SyncResult(success: false, error: 'Sync already in progress');
    }

    if (!_networkMonitor.isOnline) {
      debugPrint('[SyncService] Offline, skipping sync');
      return SyncResult(success: false, error: 'No internet connection');
    }

    _isSyncing = true;
    _setState(SyncState.syncing);

    try {
      debugPrint('[SyncService] Starting sync...');

      // Push local changes first
      final pushResult = await _pushChanges();

      // Then pull server changes
      final pullResult = await _pullChanges();

      final result = SyncResult(
        success: true,
        pushed: pushResult,
        pulled: pullResult,
      );

      _setState(SyncState.success);
      _resultController.add(result);

      debugPrint('[SyncService] Sync completed: $result');
      return result;
    } catch (e) {
      debugPrint('[SyncService] Sync failed: $e');

      final result = SyncResult(success: false, error: e.toString());
      _setState(SyncState.error);
      _resultController.add(result);

      return result;
    } finally {
      _isSyncing = false;
      // Reset to idle after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentState != SyncState.syncing) {
          _setState(SyncState.idle);
        }
      });
    }
  }

  /// Push local changes to server
  Future<int> _pushChanges() async {
    int pushed = 0;

    // Get pending sync items
    final pendingItems = await _db.getPendingSyncItems();
    debugPrint('[SyncService] Found ${pendingItems.length} pending items');

    for (final item in pendingItems) {
      if (item.entityType != 'marker') continue;

      try {
        // Mark as in progress
        await _db.updateSyncQueueStatus(item.id, QueueStatus.inProgress);

        switch (item.operation) {
          case SyncOperation.create:
            await _pushCreate(item);
            pushed++;
            break;
          case SyncOperation.update:
            await _pushUpdate(item);
            pushed++;
            break;
          case SyncOperation.delete:
            await _pushDelete(item);
            pushed++;
            break;
        }

        // Remove from queue on success
        await _db.deleteSyncQueueItem(item.id);
      } catch (e) {
        debugPrint('[SyncService] Failed to push ${item.operation}: $e');

        // Increment retry count
        await _db.incrementRetryCount(item.id);

        // Check if max retries exceeded
        if (item.retryCount + 1 >= _maxRetries) {
          await _db.updateSyncQueueStatus(
            item.id,
            QueueStatus.failed,
            error: e.toString(),
          );
        } else {
          await _db.updateSyncQueueStatus(
            item.id,
            QueueStatus.pending,
            error: e.toString(),
          );
        }
      }
    }

    return pushed;
  }

  /// Push a create operation
  Future<void> _pushCreate(SyncQueueData item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    final response = await _remoteDataSource.createMarker(
      name: payload['name'] as String,
      latitude: payload['latitude'] as String,
      longitude: payload['longitude'] as String,
      description: payload['description'] as String?,
      strain: payload['strain'] as String?,
      quantity: payload['quantity'] as int?,
      ownerName: payload['owner_name'] as String?,
      ownerContact: payload['owner_contact'] as String?,
      imagePath: item.localImagePath,
    );

    // Update local marker with server data
    await _localDataSource.updateMarkerAfterSync(
      localId: item.entityId,
      serverId: response.id,
      shortCode: response.shortCode,
      imageUrl: response.imageUrl,
    );

    debugPrint(
        '[SyncService] Created marker on server: ${response.id} (local: ${item.entityId})');
  }

  /// Push an update operation
  Future<void> _pushUpdate(SyncQueueData item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    final response = await _remoteDataSource.updateMarker(
      id: item.entityId,
      name: payload['name'] as String?,
      latitude: payload['latitude'] as String?,
      longitude: payload['longitude'] as String?,
      description: payload['description'] as String?,
      strain: payload['strain'] as String?,
      quantity: payload['quantity'] as int?,
      ownerName: payload['owner_name'] as String?,
      ownerContact: payload['owner_contact'] as String?,
      imagePath: item.localImagePath,
    );

    // Update local marker sync status
    await _db.updateMarkerSyncStatus(item.entityId, SyncStatus.synced);

    debugPrint('[SyncService] Updated marker on server: ${response.id}');
  }

  /// Push a delete operation
  Future<void> _pushDelete(SyncQueueData item) async {
    await _remoteDataSource.deleteMarker(item.entityId);

    // Hard delete local marker
    await _db.hardDeleteMarker(item.entityId);

    debugPrint('[SyncService] Deleted marker on server: ${item.entityId}');
  }

  /// Pull changes from server
  Future<int> _pullChanges() async {
    int pulled = 0;

    try {
      // Fetch all markers from server
      final serverMarkers = await _remoteDataSource.getAllMarkers();
      debugPrint(
          '[SyncService] Fetched ${serverMarkers.length} markers from server');

      final serverIds = <String>[];

      for (final serverMarker in serverMarkers) {
        serverIds.add(serverMarker.id);

        // Check if marker exists locally
        final localMarker = await _localDataSource.getMarkerById(serverMarker.id);

        if (localMarker == null) {
          // New marker from server - create locally
          final entity = EntitiesMarker.fromListResponse(serverMarker);
          await _localDataSource.upsertFromServer(entity);
          pulled++;
          debugPrint(
              '[SyncService] Pulled new marker from server: ${serverMarker.id}');
        } else {
          // Marker exists - check for conflicts
          final dbMarker = await _db.getMarkerById(serverMarker.id);
          if (dbMarker != null && dbMarker.syncStatus == SyncStatus.synced) {
            // No local changes, update from server
            final entity = EntitiesMarker.fromListResponse(serverMarker);
            await _localDataSource.upsertFromServer(entity);
            pulled++;
          }
          // If local has pending changes, keep local version (will push on next sync)
        }
      }

      // Remove markers that were deleted on server
      await _localDataSource.removeDeletedFromServer(serverIds);
    } catch (e) {
      debugPrint('[SyncService] Failed to pull changes: $e');
      rethrow;
    }

    return pulled;
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _db.getPendingSyncCount();
  }

  /// Clear failed sync items
  Future<void> clearFailedItems() async {
    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.status == QueueStatus.failed) {
        await _db.deleteSyncQueueItem(item.id);
      }
    }
  }

  /// Retry failed sync items
  Future<void> retryFailedItems() async {
    final items = await _db.getPendingSyncItems();
    for (final item in items) {
      if (item.status == QueueStatus.failed) {
        await _db.updateSyncQueueStatus(item.id, QueueStatus.pending);
      }
    }
  }

  /// Set sync state and notify listeners
  void _setState(SyncState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
    _resultController.close();
  }
}
