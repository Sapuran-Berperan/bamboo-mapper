import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connection status
enum NetworkStatus {
  /// Connected via WiFi
  wifi,

  /// Connected via mobile data
  mobile,

  /// No internet connection
  offline,
}

/// Monitors network connectivity status
class NetworkMonitor {
  NetworkMonitor._();
  static final NetworkMonitor instance = NetworkMonitor._();

  final Connectivity _connectivity = Connectivity();

  /// Stream controller for network status changes
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  /// Current network status
  NetworkStatus _currentStatus = NetworkStatus.offline;

  /// Subscription to connectivity changes
  StreamSubscription<ConnectivityResult>? _subscription;

  /// Whether the monitor has been initialized
  bool _initialized = false;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether currently online (WiFi or mobile)
  bool get isOnline =>
      _currentStatus == NetworkStatus.wifi ||
      _currentStatus == NetworkStatus.mobile;

  /// Whether connected via WiFi
  bool get isWifi => _currentStatus == NetworkStatus.wifi;

  /// Whether connected via mobile data
  bool get isMobile => _currentStatus == NetworkStatus.mobile;

  /// Whether offline
  bool get isOffline => _currentStatus == NetworkStatus.offline;

  /// Initialize the network monitor
  Future<void> initialize() async {
    if (_initialized) return;

    // Get initial status
    await _updateStatus();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (result) => _handleConnectivityChange(result),
    );

    _initialized = true;
    debugPrint('[NetworkMonitor] Initialized - Status: $_currentStatus');
  }

  /// Dispose the network monitor
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _initialized = false;
    debugPrint('[NetworkMonitor] Disposed');
  }

  /// Force refresh the network status
  Future<NetworkStatus> refresh() async {
    await _updateStatus();
    return _currentStatus;
  }

  /// Update status from connectivity check
  Future<void> _updateStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange(result);
    } catch (e) {
      debugPrint('[NetworkMonitor] Error checking connectivity: $e');
      _setStatus(NetworkStatus.offline);
    }
  }

  /// Handle connectivity change event
  void _handleConnectivityChange(ConnectivityResult result) {
    NetworkStatus newStatus;

    switch (result) {
      case ConnectivityResult.wifi:
        newStatus = NetworkStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        newStatus = NetworkStatus.mobile;
        break;
      case ConnectivityResult.ethernet:
        // Treat ethernet as wifi
        newStatus = NetworkStatus.wifi;
        break;
      case ConnectivityResult.vpn:
        // VPN can be wifi or mobile, treat as wifi
        newStatus = NetworkStatus.wifi;
        break;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.none:
      case ConnectivityResult.other:
        newStatus = NetworkStatus.offline;
        break;
    }

    _setStatus(newStatus);
  }

  /// Set the network status and notify listeners
  void _setStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      final previousStatus = _currentStatus;
      _currentStatus = status;
      _statusController.add(status);

      debugPrint(
        '[NetworkMonitor] Status changed: $previousStatus -> $status',
      );

      // Log transition for sync triggering
      if (previousStatus == NetworkStatus.offline && status != NetworkStatus.offline) {
        debugPrint('[NetworkMonitor] Network restored - sync can be triggered');
      } else if (previousStatus != NetworkStatus.offline && status == NetworkStatus.offline) {
        debugPrint('[NetworkMonitor] Network lost - entering offline mode');
      }
    }
  }
}
