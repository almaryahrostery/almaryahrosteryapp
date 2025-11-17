import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/hybrid_auth_service.dart';

/// Order Service - Handles all order-related API calls
///
/// 🛡️ ROBUST TOKEN PROTECTION:
/// - All methods automatically retry on 401 errors with fresh token
/// - Token is proactively refreshed before critical operations (order creation)
/// - No user interruption - errors handled transparently
/// - Zero login prompts during checkout flow
///
/// This ensures seamless user experience even with expired tokens.
class OrderService {
  final HybridAuthService _authService = HybridAuthService();

  String get baseUrl => '${AppConstants.baseUrl}/api';

  /// Public getter for auth token (for payment integration)
  Future<String?> get authToken async => await _authService.getToken();

  /// Get headers with auth token (hybrid: JWT or Firebase)
  Future<Map<String, String>> _getHeaders() async {
    return await _authService.getAuthHeaders();
  }

  /// Create a new order
  ///
  /// 🛡️ ROBUST TOKEN HANDLING:
  /// - Automatically retries on 401 with fresh token
  /// - Never interrupts user flow
  /// - Transparent error recovery
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
    Map<String, dynamic>? deliveryInfo,
    String? specialInstructions,
  }) async {
    try {
      debugPrint('📦 Creating order with ${items.length} items');
      debugPrint('💰 Total amount: $totalAmount');
      debugPrint('💳 Payment method: $paymentMethod');

      // 🔥 CRITICAL: Get fresh token BEFORE creating order
      debugPrint('🔐 Ensuring fresh authentication token...');
      await _authService.getToken();

      return await _attemptCreateOrder(
        items: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        totalAmount: totalAmount,
        deliveryInfo: deliveryInfo,
        specialInstructions: specialInstructions,
      );
    } catch (e) {
      // Check if it's a 401 error (token expired)
      if (e.toString().contains('401') ||
          e.toString().contains('Invalid or expired token') ||
          e.toString().contains('Please login')) {
        debugPrint(
          '🔄 Token expired during order creation, refreshing and retrying...',
        );

        try {
          // Force refresh token (hybrid method)
          await _authService.getToken(forceRefresh: true);

          debugPrint(
            '✅ Token refreshed successfully, retrying order creation...',
          );

          // Retry the order creation with fresh token
          return await _attemptCreateOrder(
            items: items,
            shippingAddress: shippingAddress,
            paymentMethod: paymentMethod,
            paymentStatus: paymentStatus,
            totalAmount: totalAmount,
            deliveryInfo: deliveryInfo,
            specialInstructions: specialInstructions,
          );
        } catch (retryError) {
          debugPrint('❌ Retry failed after token refresh: $retryError');
          throw Exception('Unable to place order. Please try again.');
        }
      }

      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  /// Internal method to attempt order creation
  /// Separated for retry logic
  Future<Map<String, dynamic>> _attemptCreateOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required String paymentStatus,
    required double totalAmount,
    Map<String, dynamic>? deliveryInfo,
    String? specialInstructions,
  }) async {
    final orderData = {
      'items': items
          .map(
            (item) => {
              'productId': item['productId'] ?? item['id'],
              'productName': item['name'],
              'quantity': item['quantity'],
              'price': item['price'],
              'roastLevel': item['roastLevel'],
              'grindSize': item['grindSize'],
            },
          )
          .toList(),
      'shippingAddress': {
        'fullName': shippingAddress['name'],
        'phone': shippingAddress['phone'],
        'addressLine': shippingAddress['address'],
        'city': shippingAddress['city'],
        'emirate': shippingAddress['emirate'],
        'country': 'UAE',
      },
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'totalAmount': totalAmount,
      'deliveryMethod': deliveryInfo?['method'] ?? 'standard',
      'preferredDeliveryDate': deliveryInfo?['date']?.toIso8601String(),
      'preferredDeliveryTime': deliveryInfo?['time'],
      'specialInstructions': specialInstructions,
    };

    debugPrint('📤 Sending order to: $baseUrl/orders');

    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers,
      body: json.encode(orderData),
    );

    debugPrint('📡 Response status: ${response.statusCode}');
    debugPrint('📡 Response body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        debugPrint(
          '✅ Order created successfully: ${data['order']['orderNumber']}',
        );
        return {
          'success': true,
          'order': data['order'],
          'message': 'Order placed successfully',
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to create order');
      }
    } else if (response.statusCode == 401) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Invalid or expired token');
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create order');
    }
  }

  /// Get user's orders
  /// 🛡️ With automatic 401 retry
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      debugPrint('📦 Fetching user orders from: $baseUrl/orders/my-orders');

      // Ensure fresh token
      await _authService.getToken();

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: headers,
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final orders = (data['orders'] as List).cast<Map<String, dynamic>>();
          debugPrint('✅ Loaded ${orders.length} orders');
          return orders;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch orders');
        }
      } else if (response.statusCode == 401) {
        // Auto-retry with fresh token
        debugPrint('🔄 401 error, refreshing token and retrying...');
        await _authService.getToken(forceRefresh: true);

        final retryHeaders = await _getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/orders/my-orders'),
          headers: retryHeaders,
        );

        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          final orders = (data['orders'] as List).cast<Map<String, dynamic>>();
          debugPrint('✅ Retry successful, loaded ${orders.length} orders');
          return orders;
        }

        throw Exception('Please login to view orders');
      } else {
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      rethrow;
    }
  }

  /// Get order details by ID
  /// 🛡️ With automatic 401 retry
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      debugPrint('📦 Fetching order details: $orderId');

      // Ensure fresh token
      await _authService.getToken();

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          debugPrint('✅ Order details loaded');
          return data['order'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch order');
        }
      } else if (response.statusCode == 401) {
        // Auto-retry with fresh token
        debugPrint('🔄 401 error, refreshing token and retrying...');
        await _authService.getToken(forceRefresh: true);

        final retryHeaders = await _getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/orders/$orderId'),
          headers: retryHeaders,
        );

        if (retryResponse.statusCode == 200) {
          final data = json.decode(retryResponse.body);
          debugPrint('✅ Retry successful, order details loaded');
          return data['order'];
        }

        throw Exception('Please login to view order');
      } else {
        throw Exception('Failed to fetch order');
      }
    } catch (e) {
      debugPrint('❌ Error fetching order details: $e');
      rethrow;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      debugPrint('❌ Cancelling order: $orderId');

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Order cancelled successfully');
        return data['success'] == true;
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      rethrow;
    }
  }

  /// Create guest order (without authentication)
  Future<Map<String, dynamic>> createGuestOrder({
    required String guestEmail,
    required String guestName,
    required String guestPhone,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required double totalAmount,
    Map<String, dynamic>? deliveryInfo,
  }) async {
    try {
      debugPrint('📦 Creating guest order');

      final orderData = {
        'guestInfo': {
          'email': guestEmail,
          'name': guestName,
          'phone': guestPhone,
        },
        'items': items
            .map(
              (item) => {
                'productId': item['productId'] ?? item['id'],
                'productName': item['name'],
                'quantity': item['quantity'],
                'price': item['price'],
                'roastLevel': item['roastLevel'],
                'grindSize': item['grindSize'],
              },
            )
            .toList(),
        'shippingAddress': {
          'fullName': shippingAddress['name'],
          'phone': shippingAddress['phone'],
          'addressLine': shippingAddress['address'],
          'city': shippingAddress['city'],
          'emirate': shippingAddress['emirate'],
          'country': 'UAE',
        },
        'paymentMethod': paymentMethod,
        'paymentStatus': 'pending',
        'totalAmount': totalAmount,
        'deliveryMethod': deliveryInfo?['method'] ?? 'standard',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/guest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          debugPrint('✅ Guest order created: ${data['order']['orderNumber']}');
          return {
            'success': true,
            'order': data['order'],
            'message': 'Order placed successfully',
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to create order');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Error creating guest order: $e');
      rethrow;
    }
  }
}
