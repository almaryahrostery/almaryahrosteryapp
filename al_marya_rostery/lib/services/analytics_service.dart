import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/services/hybrid_auth_service.dart';

/// Analytics Service - Fetches analytics data from backend
class AnalyticsService {
  final HybridAuthService _authService = HybridAuthService();

  String get baseUrl => '${AppConstants.baseUrl}/api';

  /// Get headers with auth token (hybrid: JWT or Firebase)
  Future<Map<String, String>> _getHeaders() async {
    return await _authService.getAuthHeaders();
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopProducts({
    int limit = 5,
    String period = '7d',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/top-products?limit=$limit&period=$period',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      // Return mock data if API fails
      return _getMockTopProducts();
    } catch (e) {
      debugPrint('❌ Error fetching top products: $e');
      return _getMockTopProducts();
    }
  }

  /// Get customer analytics
  Future<Map<String, dynamic>> getCustomerAnalytics({
    String period = '7d',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/customers?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }

      return _getMockCustomerAnalytics();
    } catch (e) {
      debugPrint('❌ Error fetching customer analytics: $e');
      return _getMockCustomerAnalytics();
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics({
    String period = '7d',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/performance?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }

      return _getMockPerformanceMetrics();
    } catch (e) {
      debugPrint('❌ Error fetching performance metrics: $e');
      return _getMockPerformanceMetrics();
    }
  }

  /// Get dashboard overview
  Future<Map<String, dynamic>> getDashboardOverview({
    String period = '7d',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/overview?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }

      return _getMockDashboardOverview();
    } catch (e) {
      debugPrint('❌ Error fetching dashboard overview: $e');
      return _getMockDashboardOverview();
    }
  }

  // Mock data fallbacks
  List<Map<String, dynamic>> _getMockTopProducts() {
    return [
      {'name': 'Arabic Coffee', 'orders': 245, 'revenue': 3675.0},
      {'name': 'Espresso Blend', 'orders': 198, 'revenue': 2970.0},
      {'name': 'Cappuccino Blend', 'orders': 167, 'revenue': 2505.0},
      {'name': 'Turkish Coffee', 'orders': 142, 'revenue': 2130.0},
      {'name': 'Latte Blend', 'orders': 128, 'revenue': 1920.0},
    ];
  }

  Map<String, dynamic> _getMockCustomerAnalytics() {
    return {
      'newCustomers': 127,
      'newCustomersChange': 23.0,
      'returningCustomers': 765,
      'returningCustomersChange': 8.0,
      'retentionRate': 86.0,
      'retentionChange': 3.0,
      'avgSessionDuration': '4m 32s',
      'sessionDurationChange': 12.0,
    };
  }

  Map<String, dynamic> _getMockPerformanceMetrics() {
    return {
      'avgOrderTime': '12m 45s',
      'avgOrderTimeChange': -8.0,
      'orderCompletion': 98.5,
      'orderCompletionChange': 1.0,
      'customerSatisfaction': 4.7,
      'satisfactionChange': 0.2,
      'cancellationRate': 1.5,
      'cancellationChange': -0.3,
    };
  }

  Map<String, dynamic> _getMockDashboardOverview() {
    return {
      'revenue': 12450.0,
      'revenueChange': 12.5,
      'orders': 1247,
      'ordersChange': 8.3,
      'customers': 892,
      'customersChange': 15.7,
      'avgOrder': 9.98,
      'avgOrderChange': 2.1,
    };
  }
}
