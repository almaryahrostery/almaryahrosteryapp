import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/app_constants.dart';

/// Service to fetch public configuration from backend
class ConfigService {
  static String? _cachedStripeKey;
  static bool _stripeInitialized = false;

  /// Ensure Stripe is initialized before payment
  /// Call this before showing payment UI
  static Future<void> ensureStripeInitialized() async {
    if (_stripeInitialized) {
      return; // Already initialized
    }

    try {
      final stripeKey = await getStripePublishableKey();
      Stripe.publishableKey = stripeKey;
      _stripeInitialized = true;
      print('✅ Stripe initialized on-demand');
    } catch (e) {
      print('❌ Failed to initialize Stripe: $e');
      throw Exception(
        'Unable to initialize payment system. Please check your connection.',
      );
    }
  }

  /// Fetch Stripe publishable key from backend
  /// Returns cached value if already fetched
  static Future<String> getStripePublishableKey() async {
    // Return cached value if available
    if (_cachedStripeKey != null) {
      return _cachedStripeKey!;
    }

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/config/stripe');
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: AppConstants.defaultTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _cachedStripeKey = data['data']['publishableKey'] as String;
          return _cachedStripeKey!;
        }
      }

      throw Exception('Failed to fetch Stripe configuration');
    } catch (e) {
      print('Error fetching Stripe key: $e');
      // Fallback: This should never happen in production
      // but provides safety during development
      throw Exception(
        'Could not connect to server to fetch payment configuration',
      );
    }
  }

  /// Clear cached configuration (useful for testing)
  static void clearCache() {
    _cachedStripeKey = null;
  }
}
