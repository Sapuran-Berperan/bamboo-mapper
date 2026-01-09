import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/network_monitor.dart';
import '../../core/sync/sync_service.dart';

// ============ Events ============

/// Base class for sync events
abstract class SyncEvent {}

/// Initialize sync monitoring
class SyncInitialize extends SyncEvent {}

/// Trigger manual sync
class SyncTrigger extends SyncEvent {}

/// Update network status
class SyncNetworkChanged extends SyncEvent {
  final NetworkStatus networkStatus;
  SyncNetworkChanged(this.networkStatus);
}

/// Update sync state from service
class SyncStateChanged extends SyncEvent {
  final SyncState syncState;
  SyncStateChanged(this.syncState);
}

/// Update sync result
class SyncResultReceived extends SyncEvent {
  final SyncResult result;
  SyncResultReceived(this.result);
}

/// Update pending count
class SyncPendingCountChanged extends SyncEvent {
  final int count;
  SyncPendingCountChanged(this.count);
}

// ============ State ============

/// Bloc state for sync status
class SyncBlocState {
  /// Current network status
  final NetworkStatus networkStatus;

  /// Current sync state
  final SyncState syncState;

  /// Number of pending sync operations
  final int pendingCount;

  /// Last sync result
  final SyncResult? lastResult;

  /// Last sync timestamp
  final DateTime? lastSyncAt;

  /// Error message if any
  final String? errorMessage;

  const SyncBlocState({
    this.networkStatus = NetworkStatus.offline,
    this.syncState = SyncState.idle,
    this.pendingCount = 0,
    this.lastResult,
    this.lastSyncAt,
    this.errorMessage,
  });

  /// Whether device is online
  bool get isOnline => networkStatus != NetworkStatus.offline;

  /// Whether sync is in progress
  bool get isSyncing => syncState == SyncState.syncing;

  /// Whether there are pending changes to sync
  bool get hasPendingChanges => pendingCount > 0;

  /// Create a copy with updated fields
  SyncBlocState copyWith({
    NetworkStatus? networkStatus,
    SyncState? syncState,
    int? pendingCount,
    SyncResult? lastResult,
    DateTime? lastSyncAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncBlocState(
      networkStatus: networkStatus ?? this.networkStatus,
      syncState: syncState ?? this.syncState,
      pendingCount: pendingCount ?? this.pendingCount,
      lastResult: lastResult ?? this.lastResult,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ============ Bloc ============

/// BLoC for managing sync state
class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  final NetworkMonitor _networkMonitor = NetworkMonitor.instance;
  final SyncService _syncService = SyncService.instance;

  StreamSubscription<NetworkStatus>? _networkSubscription;
  StreamSubscription<SyncState>? _syncStateSubscription;
  StreamSubscription<SyncResult>? _syncResultSubscription;

  SyncBloc() : super(const SyncBlocState()) {
    on<SyncInitialize>(_onInitialize);
    on<SyncTrigger>(_onTrigger);
    on<SyncNetworkChanged>(_onNetworkChanged);
    on<SyncStateChanged>(_onSyncStateChanged);
    on<SyncResultReceived>(_onSyncResultReceived);
    on<SyncPendingCountChanged>(_onPendingCountChanged);
  }

  /// Initialize sync monitoring
  Future<void> _onInitialize(
    SyncInitialize event,
    Emitter<SyncBlocState> emit,
  ) async {
    // Initialize network monitor
    await _networkMonitor.initialize();

    // Subscribe to network changes
    _networkSubscription = _networkMonitor.statusStream.listen((status) {
      add(SyncNetworkChanged(status));
    });

    // Subscribe to sync state changes
    _syncStateSubscription = _syncService.stateStream.listen((state) {
      add(SyncStateChanged(state));
    });

    // Subscribe to sync results
    _syncResultSubscription = _syncService.resultStream.listen((result) {
      add(SyncResultReceived(result));
    });

    // Get initial pending count
    final pendingCount = await _syncService.getPendingSyncCount();

    // Emit initial state
    emit(state.copyWith(
      networkStatus: _networkMonitor.currentStatus,
      pendingCount: pendingCount,
    ));

    // Auto-sync if online and has pending changes
    if (_networkMonitor.isOnline && pendingCount > 0) {
      add(SyncTrigger());
    }
  }

  /// Handle manual sync trigger
  Future<void> _onTrigger(
    SyncTrigger event,
    Emitter<SyncBlocState> emit,
  ) async {
    if (!state.isOnline) {
      emit(state.copyWith(
        errorMessage: 'Tidak ada koneksi internet',
      ));
      return;
    }

    if (state.isSyncing) {
      return;
    }

    // Start sync
    await _syncService.sync();
  }

  /// Handle network status change
  Future<void> _onNetworkChanged(
    SyncNetworkChanged event,
    Emitter<SyncBlocState> emit,
  ) async {
    final wasOffline = !state.isOnline;
    final isNowOnline = event.networkStatus != NetworkStatus.offline;

    emit(state.copyWith(
      networkStatus: event.networkStatus,
      clearError: true,
    ));

    // Auto-sync when coming back online with pending changes
    if (wasOffline && isNowOnline && state.hasPendingChanges) {
      add(SyncTrigger());
    }
  }

  /// Handle sync state change
  void _onSyncStateChanged(
    SyncStateChanged event,
    Emitter<SyncBlocState> emit,
  ) {
    emit(state.copyWith(
      syncState: event.syncState,
      clearError: event.syncState == SyncState.syncing,
    ));
  }

  /// Handle sync result
  Future<void> _onSyncResultReceived(
    SyncResultReceived event,
    Emitter<SyncBlocState> emit,
  ) async {
    // Update pending count
    final pendingCount = await _syncService.getPendingSyncCount();

    emit(state.copyWith(
      lastResult: event.result,
      lastSyncAt: DateTime.now(),
      pendingCount: pendingCount,
      errorMessage: event.result.success ? null : event.result.error,
    ));
  }

  /// Handle pending count change
  void _onPendingCountChanged(
    SyncPendingCountChanged event,
    Emitter<SyncBlocState> emit,
  ) {
    emit(state.copyWith(pendingCount: event.count));
  }

  /// Refresh pending count
  Future<void> refreshPendingCount() async {
    final count = await _syncService.getPendingSyncCount();
    add(SyncPendingCountChanged(count));
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    _syncStateSubscription?.cancel();
    _syncResultSubscription?.cancel();
    return super.close();
  }
}
