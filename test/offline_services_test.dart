import 'package:flutter_test/flutter_test.dart';
import 'package:bamboo_app/src/core/database/database.dart';
import 'package:bamboo_app/src/core/network/network_monitor.dart';
import 'package:bamboo_app/src/core/sync/sync_service.dart';
import 'package:bamboo_app/src/data/datasources/marker_local_datasource.dart';

void main() {
  group('Offline Services Tests', () {
    group('SyncStatus Constants', () {
      test('should have correct sync status values', () {
        expect(SyncStatus.synced, 'synced');
        expect(SyncStatus.pendingCreate, 'pending_create');
        expect(SyncStatus.pendingUpdate, 'pending_update');
        expect(SyncStatus.pendingDelete, 'pending_delete');
      });
    });

    group('SyncOperation Constants', () {
      test('should have correct sync operation values', () {
        expect(SyncOperation.create, 'CREATE');
        expect(SyncOperation.update, 'UPDATE');
        expect(SyncOperation.delete, 'DELETE');
      });
    });

    group('QueueStatus Constants', () {
      test('should have correct queue status values', () {
        expect(QueueStatus.pending, 'pending');
        expect(QueueStatus.inProgress, 'in_progress');
        expect(QueueStatus.failed, 'failed');
        expect(QueueStatus.completed, 'completed');
      });
    });

    group('SyncMetadataKeys Constants', () {
      test('should have correct metadata keys', () {
        expect(SyncMetadataKeys.lastFullSync, 'last_full_sync');
        expect(SyncMetadataKeys.lastMarkersSync, 'last_markers_sync');
        expect(SyncMetadataKeys.syncInProgress, 'sync_in_progress');
        expect(SyncMetadataKeys.pendingCount, 'pending_count');
      });
    });

    group('NetworkStatus', () {
      test('should have wifi, mobile, and offline statuses', () {
        expect(NetworkStatus.values.length, 3);
        expect(NetworkStatus.wifi, isNotNull);
        expect(NetworkStatus.mobile, isNotNull);
        expect(NetworkStatus.offline, isNotNull);
      });
    });

    group('SyncState', () {
      test('should have idle, syncing, success, and error states', () {
        expect(SyncState.values.length, 4);
        expect(SyncState.idle, isNotNull);
        expect(SyncState.syncing, isNotNull);
        expect(SyncState.success, isNotNull);
        expect(SyncState.error, isNotNull);
      });
    });

    group('SyncResult', () {
      test('should create success result', () {
        final result = SyncResult(
          success: true,
          pushed: 5,
          pulled: 3,
        );

        expect(result.success, true);
        expect(result.pushed, 5);
        expect(result.pulled, 3);
        expect(result.error, isNull);
      });

      test('should create error result', () {
        final result = SyncResult(
          success: false,
          error: 'Network error',
        );

        expect(result.success, false);
        expect(result.pushed, 0);
        expect(result.pulled, 0);
        expect(result.error, 'Network error');
      });

      test('should have correct toString', () {
        final result = SyncResult(
          success: true,
          pushed: 2,
          pulled: 4,
        );

        expect(
          result.toString(),
          'SyncResult(success: true, pushed: 2, pulled: 4, error: null)',
        );
      });
    });

    group('NetworkMonitor', () {
      test('should be a singleton', () {
        final instance1 = NetworkMonitor.instance;
        final instance2 = NetworkMonitor.instance;
        expect(identical(instance1, instance2), true);
      });

      test('should start with offline status', () {
        final monitor = NetworkMonitor.instance;
        // Before initialization, status is offline
        expect(monitor.currentStatus, NetworkStatus.offline);
      });

      test('isOnline should return correct value', () {
        final monitor = NetworkMonitor.instance;
        // Test the isOnline getter logic
        expect(monitor.isOffline, true); // Should be offline initially
      });
    });

    // Note: SyncService tests are skipped because they require dotenv initialization
    // These would be integration tests requiring full environment setup
    group('SyncService', () {
      test('SyncState enum should have correct values', () {
        // Test the enum values without instantiating SyncService
        expect(SyncState.idle, isNotNull);
        expect(SyncState.syncing, isNotNull);
        expect(SyncState.success, isNotNull);
        expect(SyncState.error, isNotNull);
      });
    });

    group('MarkerLocalDataSource', () {
      test('should be a singleton', () {
        final instance1 = MarkerLocalDataSource.instance;
        final instance2 = MarkerLocalDataSource.instance;
        expect(identical(instance1, instance2), true);
      });
    });
  });
}
