import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity status enum
enum ConnectivityStatus { online, offline, unknown }

/// Service for monitoring network connectivity
///
/// Features:
/// - Real-time connectivity monitoring
/// - Stream-based status updates
/// - Easy integration with UI
class ConnectivityService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Current status
  ConnectivityStatus _status = ConnectivityStatus.unknown;

  // Stream controller for broadcasting status changes
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  /// Get current connectivity status
  ConnectivityStatus get status => _status;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Check if currently online
  bool get isOnline => _status == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => _status == ConnectivityStatus.offline;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    try {
      // Get initial status
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);

      // Listen for changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateStatus,
        onError: (error) {
          debugPrint('ConnectivityService: Error in stream: $error');
          _setStatus(ConnectivityStatus.unknown);
        },
      );

      debugPrint('ConnectivityService: Initialized with status $_status');
    } catch (e) {
      debugPrint('ConnectivityService: Error initializing: $e');
      _setStatus(ConnectivityStatus.unknown);
    }
  }

  /// Update status based on connectivity results
  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _setStatus(ConnectivityStatus.offline);
    } else {
      _setStatus(ConnectivityStatus.online);
    }
  }

  /// Set status and notify listeners
  void _setStatus(ConnectivityStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
      debugPrint('ConnectivityService: Status changed to $_status');
    }
  }

  /// Check connectivity status on demand
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return _status;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity: $e');
      return ConnectivityStatus.unknown;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    debugPrint('ConnectivityService: Disposed');
  }
}
