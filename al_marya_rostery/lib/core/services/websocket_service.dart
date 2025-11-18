import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../constants/app_constants.dart';

/// WebSocketService handles real-time communication with the backend
/// for delivery tracking, order status updates, and payment confirmations.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Event streams for reactive updates
  final _deliveryUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get deliveryUpdates =>
      _deliveryUpdateController.stream;
  Stream<Map<String, dynamic>> get driverLocationUpdates =>
      _driverLocationController.stream;
  Stream<Map<String, dynamic>> get paymentUpdates =>
      _paymentUpdateController.stream;
  Stream<Map<String, dynamic>> get orderStatusUpdates =>
      _orderStatusController.stream;

  bool get isConnected => _isConnected;

  /// Connect to WebSocket server with authentication
  Future<void> connect(String authToken, {bool isDevelopment = false}) async {
    if (_isConnected) {
      debugPrint('WebSocket already connected');
      return;
    }

    // Use AppConstants.baseUrl for consistent environment configuration
    final serverUrl = AppConstants.baseUrl;

    try {
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setAuth({'token': authToken})
            .build(),
      );

      _setupEventListeners();

      _socket!.connect();

      debugPrint('🔌 Connecting to WebSocket server: $serverUrl');
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      rethrow;
    }
  }

  /// Setup event listeners for Socket.IO events
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('✅ WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('❌ WebSocket disconnected');
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ WebSocket connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('❌ WebSocket error: $error');
    });

    // Delivery tracking events
    _socket!.on('delivery_update', (data) {
      debugPrint('📦 Delivery update received: $data');
      if (data is Map) {
        _deliveryUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('driver_location_update', (data) {
      debugPrint('📍 Driver location update: $data');
      if (data is Map) {
        _driverLocationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('payment_update', (data) {
      debugPrint('💳 Payment update: $data');
      if (data is Map) {
        _paymentUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('order_status_change', (data) {
      debugPrint('📊 Order status change: $data');
      if (data is Map) {
        _orderStatusController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Join an order room to receive specific order updates
  void joinOrderRoom(String orderId) {
    if (!_isConnected || _socket == null) {
      debugPrint('⚠️ Cannot join room - not connected');
      return;
    }

    _socket!.emit('join_order_room', {'orderId': orderId});
    debugPrint('🚪 Joined order room: $orderId');
  }

  /// Leave an order room
  void leaveOrderRoom(String orderId) {
    if (_socket == null) return;

    _socket!.emit('leave_order_room', {'orderId': orderId});
    debugPrint('🚪 Left order room: $orderId');
  }

  /// Request current order status
  void requestOrderStatus(String orderId) {
    if (!_isConnected || _socket == null) {
      debugPrint('⚠️ Cannot request status - not connected');
      return;
    }

    _socket!.emit('request_order_status', {'orderId': orderId});
    debugPrint('📡 Requested order status for: $orderId');
  }

  /// Request current driver location
  void requestDriverLocation(String orderId) {
    if (!_isConnected || _socket == null) {
      debugPrint('⚠️ Cannot request location - not connected');
      return;
    }

    _socket!.emit('request_driver_location', {'orderId': orderId});
    debugPrint('📡 Requested driver location for: $orderId');
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_socket == null) return;

    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
    _isConnected = false;

    debugPrint('🔌 WebSocket disconnected');
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _deliveryUpdateController.close();
    _driverLocationController.close();
    _paymentUpdateController.close();
    _orderStatusController.close();
  }
}
