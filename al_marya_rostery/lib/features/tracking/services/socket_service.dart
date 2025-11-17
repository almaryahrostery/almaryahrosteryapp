import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';

/// Socket event data classes
class DriverLocationEvent {
  final String orderId;
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  DriverLocationEvent({
    required this.orderId,
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory DriverLocationEvent.fromJson(Map<String, dynamic> json) {
    return DriverLocationEvent(
      orderId: json['orderId'] ?? '',
      lat: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class OrderStatusEvent {
  final String orderId;
  final String status;
  final DateTime timestamp;
  final String? message;

  OrderStatusEvent({
    required this.orderId,
    required this.status,
    required this.timestamp,
    this.message,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      message: json['message'],
    );
  }
}

class ETAUpdateEvent {
  final String orderId;
  final DateTime etaStart;
  final DateTime etaEnd;
  final int? distanceMeters;
  final int? durationSeconds;

  ETAUpdateEvent({
    required this.orderId,
    required this.etaStart,
    required this.etaEnd,
    this.distanceMeters,
    this.durationSeconds,
  });

  factory ETAUpdateEvent.fromJson(Map<String, dynamic> json) {
    return ETAUpdateEvent(
      orderId: json['orderId'] ?? '',
      etaStart: DateTime.parse(json['etaStart'] ?? json['start']),
      etaEnd: DateTime.parse(json['etaEnd'] ?? json['end']),
      distanceMeters: json['distanceMeters'],
      durationSeconds: json['durationSeconds'],
    );
  }
}

/// Singleton Socket.IO service for real-time tracking
class TrackingSocketService {
  static final TrackingSocketService _instance =
      TrackingSocketService._internal();

  factory TrackingSocketService() => _instance;

  TrackingSocketService._internal();

  IO.Socket? _socket;
  String? _currentOrderId;
  bool _isConnected = false;

  // Stream controllers for events
  final _driverLocationController =
      StreamController<DriverLocationEvent>.broadcast();
  final _orderStatusController = StreamController<OrderStatusEvent>.broadcast();
  final _etaUpdateController = StreamController<ETAUpdateEvent>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // Public streams
  Stream<DriverLocationEvent> get driverLocationStream =>
      _driverLocationController.stream;
  Stream<OrderStatusEvent> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<ETAUpdateEvent> get etaUpdateStream => _etaUpdateController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool get isConnected => _isConnected;
  String? get currentOrderId => _currentOrderId;

  /// Initialize and connect to Socket.IO server
  Future<void> connect({String? authToken}) async {
    if (_socket != null && _isConnected) {
      AppLogger.debug('Socket already connected');
      return;
    }

    try {
      final socketUrl = AppConstants.socketUrl ?? AppConstants.baseUrl;

      AppLogger.info('Connecting to Socket.IO at: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .setExtraHeaders({
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            })
            .build(),
      );

      _setupSocketListeners();

      // Connect
      _socket!.connect();

      AppLogger.info('Socket connection initiated');
    } catch (e) {
      AppLogger.error('Socket connection error: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      AppLogger.info('Socket connected successfully');
      _isConnected = true;
      _connectionStatusController.add(true);

      // Rejoin order room if we were tracking an order
      if (_currentOrderId != null) {
        joinOrderRoom(_currentOrderId!);
      }
    });

    _socket!.onDisconnect((_) {
      AppLogger.warning('Socket disconnected');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((error) {
      AppLogger.error('Socket connection error: $error');
      _isConnected = false;
      _connectionStatusController.add(false);
    });

    _socket!.onError((error) {
      AppLogger.error('Socket error: $error');
    });

    // Tracking events
    _socket!.on('driver_location', (data) {
      try {
        final event = DriverLocationEvent.fromJson(
          data is Map<String, dynamic> ? data : {'orderId': _currentOrderId},
        );
        AppLogger.debug('Received driver location: ${event.lat}, ${event.lng}');
        _driverLocationController.add(event);
      } catch (e) {
        AppLogger.error('Error parsing driver_location event: $e');
      }
    });

    _socket!.on('order_status', (data) {
      try {
        final event = OrderStatusEvent.fromJson(
          data is Map<String, dynamic> ? data : {},
        );
        AppLogger.info('Order status updated: ${event.status}');
        _orderStatusController.add(event);
      } catch (e) {
        AppLogger.error('Error parsing order_status event: $e');
      }
    });

    _socket!.on('eta_update', (data) {
      try {
        final event = ETAUpdateEvent.fromJson(
          data is Map<String, dynamic> ? data : {},
        );
        AppLogger.debug('ETA updated: ${event.etaStart} - ${event.etaEnd}');
        _etaUpdateController.add(event);
      } catch (e) {
        AppLogger.error('Error parsing eta_update event: $e');
      }
    });

    // Reconnection events
    _socket!.onReconnect((_) {
      AppLogger.info('Socket reconnected');
      _isConnected = true;
      _connectionStatusController.add(true);

      // Rejoin order room
      if (_currentOrderId != null) {
        joinOrderRoom(_currentOrderId!);
      }
    });

    _socket!.onReconnectError((error) {
      AppLogger.error('Socket reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      AppLogger.error('Socket reconnection failed');
      _isConnected = false;
      _connectionStatusController.add(false);
    });
  }

  /// Join an order tracking room
  void joinOrderRoom(String orderId) {
    if (_socket == null || !_isConnected) {
      AppLogger.warning('Cannot join room: socket not connected');
      return;
    }

    _currentOrderId = orderId;
    final roomName = 'order_room_$orderId';

    AppLogger.info('Joining order room: $roomName');

    _socket!.emit('join_order_room', {
      'orderId': orderId,
      'roomName': roomName,
    });

    // Listen for join confirmation
    _socket!.once('joined_order_room', (data) {
      AppLogger.info('Successfully joined order room: $roomName');
    });
  }

  /// Leave current order room
  void leaveOrderRoom() {
    if (_socket == null || _currentOrderId == null) return;

    final roomName = 'order_room_$_currentOrderId';

    AppLogger.info('Leaving order room: $roomName');

    _socket!.emit('leave_order_room', {
      'orderId': _currentOrderId,
      'roomName': roomName,
    });

    _currentOrderId = null;
  }

  /// Emit a custom event
  void emit(String event, dynamic data) {
    if (_socket == null || !_isConnected) {
      AppLogger.warning('Cannot emit event: socket not connected');
      return;
    }

    _socket!.emit(event, data);
  }

  /// Disconnect from socket
  void disconnect() {
    if (_socket == null) return;

    AppLogger.info('Disconnecting socket');

    leaveOrderRoom();
    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _driverLocationController.close();
    _orderStatusController.close();
    _etaUpdateController.close();
    _connectionStatusController.close();
  }

  /// Force reconnection
  void reconnect() {
    if (_socket != null) {
      _socket!.connect();
    }
  }
}
