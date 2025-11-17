import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/hybrid_auth_service.dart';
import '../models/tracking_model.dart';
import 'socket_service.dart';

/// Tracking service for API calls and real-time updates
class TrackingService extends ChangeNotifier {
  final TrackingSocketService _socketService = TrackingSocketService();
  final HybridAuthService _authService = HybridAuthService();

  LiveOrderTracking? _currentTracking;
  bool _isLoading = false;
  String? _error;
  Timer? _etaRecalcTimer;
  Timer? _stationaryCheckTimer;
  DateTime? _lastDriverLocationUpdate;
  LocationModel? _lastDriverLocation;

  // Getters
  LiveOrderTracking? get currentTracking => _currentTracking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _socketService.isConnected;

  /// Initialize tracking for an order
  Future<void> initializeTracking(String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch initial order data
      await _fetchOrderTracking(orderId);

      // Connect to socket if not already connected
      if (!_socketService.isConnected) {
        final token = await _authService.getToken();
        await _socketService.connect(authToken: token);
      }

      // Join order room
      _socketService.joinOrderRoom(orderId);

      // Setup socket listeners
      _setupSocketListeners();

      // Start stationary check timer
      _startStationaryCheck();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize tracking: $e';
      _isLoading = false;
      AppLogger.error('Tracking initialization error: $e');
      notifyListeners();
    }
  }

  /// Fetch order tracking data from API
  Future<void> _fetchOrderTracking(String orderId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentTracking = LiveOrderTracking.fromJson(data);
        _lastDriverLocation = _currentTracking?.driverLocation;
        _lastDriverLocationUpdate = DateTime.now();
        notifyListeners();
        AppLogger.info('Order tracking data loaded for: $orderId');
      } else {
        throw Exception('Failed to load tracking: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching order tracking: $e');
      rethrow;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    // Listen to driver location updates
    _socketService.driverLocationStream.listen((event) {
      _handleDriverLocationUpdate(event);
    });

    // Listen to order status updates
    _socketService.orderStatusStream.listen((event) {
      _handleOrderStatusUpdate(event);
    });

    // Listen to ETA updates
    _socketService.etaUpdateStream.listen((event) {
      _handleETAUpdate(event);
    });

    // Listen to connection status
    _socketService.connectionStatusStream.listen((isConnected) {
      if (isConnected && _currentTracking != null) {
        AppLogger.info('Reconnected - rejoining room');
      }
      notifyListeners();
    });
  }

  /// Handle driver location update
  void _handleDriverLocationUpdate(DriverLocationEvent event) {
    if (_currentTracking == null ||
        _currentTracking!.orderId != event.orderId) {
      return;
    }

    final newLocation = LocationModel(
      lat: event.lat,
      lng: event.lng,
      updatedAt: event.timestamp,
      speed: event.speed,
      heading: event.heading,
    );

    _lastDriverLocation = _currentTracking!.driverLocation;
    _lastDriverLocationUpdate = DateTime.now();

    _currentTracking = _currentTracking!.copyWith(
      driverLocation: newLocation,
      lastUpdate: DateTime.now(),
    );

    // Trigger ETA recalculation (throttled)
    _scheduleETARecalculation();

    notifyListeners();
  }

  /// Handle order status update
  void _handleOrderStatusUpdate(OrderStatusEvent event) {
    if (_currentTracking == null ||
        _currentTracking!.orderId != event.orderId) {
      return;
    }

    final newStatus = OrderStatus.fromString(event.status);
    final timelineEntry = TimelineEntry(
      stage: event.status,
      time: event.timestamp,
      message: event.message,
    );

    _currentTracking = _currentTracking!.copyWith(
      status: newStatus,
      timeline: [..._currentTracking!.timeline, timelineEntry],
      lastUpdate: DateTime.now(),
    );

    notifyListeners();
    AppLogger.info('Order status updated to: ${newStatus.displayName}');
  }

  /// Handle ETA update
  void _handleETAUpdate(ETAUpdateEvent event) {
    if (_currentTracking == null ||
        _currentTracking!.orderId != event.orderId) {
      return;
    }

    final newETA = ETAModel(
      start: event.etaStart,
      end: event.etaEnd,
      distanceMeters: event.distanceMeters,
      durationSeconds: event.durationSeconds,
    );

    _currentTracking = _currentTracking!.copyWith(
      eta: newETA,
      lastUpdate: DateTime.now(),
    );

    notifyListeners();
  }

  /// Schedule ETA recalculation (throttled to every 3 seconds)
  void _scheduleETARecalculation() {
    if (_etaRecalcTimer?.isActive ?? false) {
      return; // Already scheduled
    }

    _etaRecalcTimer = Timer(const Duration(seconds: 3), () {
      _recalculateETA();
    });
  }

  /// Recalculate ETA based on current driver location
  Future<void> _recalculateETA() async {
    if (_currentTracking == null || _currentTracking!.driverLocation == null) {
      return;
    }

    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/orders/calculate-eta'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'orderId': _currentTracking!.orderId,
          'driverLocation': _currentTracking!.driverLocation!.toJson(),
          'userLocation': _currentTracking!.userLocation.toJson(),
          'isPickedUp': _currentTracking!.isPickedUp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eta = ETAModel.fromJson(data['eta']);

        _currentTracking = _currentTracking!.copyWith(
          eta: eta,
          lastUpdate: DateTime.now(),
        );

        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('ETA calculation error: $e');
    }
  }

  /// Start checking if driver is stationary
  void _startStationaryCheck() {
    _stationaryCheckTimer?.cancel();
    _stationaryCheckTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkDriverStationary(),
    );
  }

  /// Check if driver has been stationary for > 60 seconds
  void _checkDriverStationary() {
    if (_currentTracking == null ||
        _lastDriverLocation == null ||
        _currentTracking!.driverLocation == null ||
        _lastDriverLocationUpdate == null) {
      return;
    }

    final timeSinceUpdate = DateTime.now().difference(
      _lastDriverLocationUpdate!,
    );

    // Check if location hasn't changed
    final hasntMoved =
        _lastDriverLocation!.lat == _currentTracking!.driverLocation!.lat &&
        _lastDriverLocation!.lng == _currentTracking!.driverLocation!.lng;

    final isStationary = hasntMoved && timeSinceUpdate.inSeconds > 60;

    if (isStationary != _currentTracking!.isDriverStationary) {
      _currentTracking = _currentTracking!.copyWith(
        isDriverStationary: isStationary,
      );
      notifyListeners();
    }
  }

  /// Refresh tracking data
  Future<void> refresh() async {
    if (_currentTracking == null) return;

    try {
      await _fetchOrderTracking(_currentTracking!.orderId);
    } catch (e) {
      _error = 'Failed to refresh: $e';
      notifyListeners();
    }
  }

  /// Update order status (for testing/debugging)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update status: ${response.statusCode}');
      }

      AppLogger.info('Order status updated to: $status');
    } catch (e) {
      AppLogger.error('Error updating order status: $e');
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    _etaRecalcTimer?.cancel();
    _stationaryCheckTimer?.cancel();
    _socketService.leaveOrderRoom();
    super.dispose();
  }

  /// Simulate driver movement (for testing)
  void simulateDriverMovement(String orderId) {
    if (_currentTracking == null) return;

    // Create a timer that moves the driver slightly every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentTracking == null) {
        timer.cancel();
        return;
      }

      final currentLat = _currentTracking!.driverLocation?.lat ?? 25.276987;
      final currentLng = _currentTracking!.driverLocation?.lng ?? 55.296249;

      // Move slightly towards user location
      final userLat = _currentTracking!.userLocation.lat;
      final userLng = _currentTracking!.userLocation.lng;

      final newLat = currentLat + (userLat - currentLat) * 0.1;
      final newLng = currentLng + (userLng - currentLng) * 0.1;

      _handleDriverLocationUpdate(
        DriverLocationEvent(
          orderId: orderId,
          lat: newLat,
          lng: newLng,
          speed: 45.0,
          heading: 90.0,
          timestamp: DateTime.now(),
        ),
      );

      // Stop when close enough
      if ((newLat - userLat).abs() < 0.001 &&
          (newLng - userLng).abs() < 0.001) {
        timer.cancel();
        _handleOrderStatusUpdate(
          OrderStatusEvent(
            orderId: orderId,
            status: 'delivered',
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }
}
