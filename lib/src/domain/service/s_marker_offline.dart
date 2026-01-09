import '../entities/e_marker.dart';
import '../infrastructure/i_marker_offline.dart';

/// Offline-first service for marker operations
class ServiceMarkerOffline {
  final _infrastructure = InfrastructureMarkerOffline();

  /// Set current user ID for creating markers
  void setCurrentUserId(String userId) {
    _infrastructure.setCurrentUserId(userId);
  }

  /// Fetch all markers from local database
  /// Triggers background sync if online
  Future<Set<EntitiesMarker>> fetchListMarker() async {
    final res = await _infrastructure.readListMarker();
    return res.toSet();
  }

  /// Fetch single marker with full details
  Future<EntitiesMarker> fetchMarker(String markerId) async {
    final res = await _infrastructure.readMarker(markerId);
    if (res == null) {
      throw Exception('Marker tidak ditemukan');
    }
    return res;
  }

  /// Add marker (saves locally, queues for sync)
  Future<EntitiesMarker?> addMarker(EntitiesMarker marker) async {
    return await _infrastructure.createMarker(marker);
  }

  /// Update marker (saves locally, queues for sync)
  Future<void> updateMarker(EntitiesMarker marker,
      {bool keepExistingImage = false}) async {
    await _infrastructure.updateMarker(marker,
        keepExistingImage: keepExistingImage);
  }

  /// Delete marker (deletes locally, queues for sync)
  Future<void> deleteMarker(EntitiesMarker marker) async {
    await _infrastructure.deleteMarker(marker);
  }

  /// Force sync with server
  Future<void> forceSync() async {
    await _infrastructure.forceSync();
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _infrastructure.getPendingSyncCount();
  }

  /// Clear all local data (for logout)
  Future<void> clearLocalData() async {
    await _infrastructure.clearLocalData();
  }
}
