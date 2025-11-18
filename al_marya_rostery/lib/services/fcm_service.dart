import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Background message received: ${message.messageId}');
  debugPrint('Background notification: ${message.notification?.title}');
  debugPrint('Background data: ${message.data}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  // Stream controller for order updates
  final StreamController<Map<String, dynamic>> _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get orderUpdates =>
      _orderUpdateController.stream;

  /// Initialize FCM service
  Future<bool> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ FCM already initialized');
      return true;
    }

    try {
      debugPrint('🔔 Initializing FCM Service...');

      // Initialize local notifications first (required for iOS)
      await _initializeLocalNotifications();

      // Check current permission status
      final currentSettings = await _firebaseMessaging
          .getNotificationSettings();
      debugPrint(
        '📱 Current permission status: ${currentSettings.authorizationStatus}',
      );

      NotificationSettings settings;

      // Only request permission if never asked before
      if (currentSettings.authorizationStatus ==
          AuthorizationStatus.notDetermined) {
        debugPrint('📱 First time - requesting notification permissions...');
        settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        );
        debugPrint('📱 Permission result: ${settings.authorizationStatus}');
      } else if (currentSettings.authorizationStatus ==
          AuthorizationStatus.denied) {
        debugPrint(
          'ℹ️ Notifications previously denied - user can enable in iOS Settings:',
        );
        debugPrint(
          '   Settings → ALMARYAH ROSTERY → Notifications → Allow Notifications',
        );
        settings = currentSettings;
        // Continue initialization - app should work without notifications
      } else {
        settings = currentSettings;
        debugPrint('✅ Notifications already authorized');
      }

      // Don't fail initialization if denied - app needs to work without notifications
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          '⚠️ Notifications disabled - app will continue without push notifications',
        );
        _initialized = true;
        return false; // Return false but don't throw error
      }

      // For iOS: Get APNS token first before getting FCM token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          debugPrint('🍎 iOS detected - getting APNS token...');
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken != null) {
            debugPrint(
              '✅ APNS token obtained: ${apnsToken.substring(0, 20)}...',
            );
          } else {
            debugPrint('⚠️ APNS token not available yet, waiting...');
            // Wait a bit for APNS token to be available
            await Future.delayed(const Duration(seconds: 2));
            final retryToken = await _firebaseMessaging.getAPNSToken();
            if (retryToken != null) {
              debugPrint(
                '✅ APNS token obtained after retry: ${retryToken.substring(0, 20)}...',
              );
            } else {
              debugPrint(
                '⚠️ APNS token still not available - FCM may not work until it is set',
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error getting APNS token: $e');
        }
      }

      // Get FCM token (this will work after APNS token is available on iOS)
      try {
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          debugPrint('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
          await _saveFCMToken(_fcmToken!);
        } else {
          debugPrint('⚠️ Failed to get FCM token - may need to retry later');
        }
      } catch (e) {
        debugPrint('⚠️ Error getting FCM token: $e');
        // Don't fail initialization - token may become available later
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed');
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });

      _initialized = true;
      debugPrint('✅ FCM Service initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing FCM: $e');
      debugPrint('Stack trace: $stackTrace');
      // Mark as initialized even on error to prevent repeated initialization attempts
      _initialized = true;
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request notification permission with user context
  Future<bool> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted && !_initialized) {
        // If permission granted and not initialized, initialize now
        await initialize();
      }

      return granted;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('📱 Local notification tapped: ${details.payload}');
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            _orderUpdateController.add(data);
          } catch (e) {
            debugPrint('❌ Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground message received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);

    // Broadcast order update
    if (message.data.isNotEmpty && message.data['orderId'] != null) {
      _orderUpdateController.add(message.data);
    }
  }

  /// Handle notification tap (background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped');
    debugPrint('Data: ${message.data}');

    // Broadcast order update to navigate to order screen
    if (message.data.isNotEmpty && message.data['orderId'] != null) {
      _orderUpdateController.add({
        ...message.data,
        'tapped': true, // Flag to indicate notification was tapped
      });
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFA89A6A), // Olive gold color
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  /// Save FCM token to backend
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firebaseToken = prefs.getString('firebase_token');

      if (firebaseToken == null) {
        debugPrint('⚠️ No Firebase auth token found, skipping FCM token save');
        return;
      }

      // Use AppConstants.baseUrl for consistent environment configuration
      final baseUrl = AppConstants.baseUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/me/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token saved to backend');
      } else {
        debugPrint('⚠️ Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _orderUpdateController.close();
  }
}
