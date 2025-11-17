import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../constants/app_constants.dart';
import 'hybrid_auth_service.dart';

/// Service for handling Stripe payment integration
class PaymentService {
  static String get _baseUrl => '${AppConstants.baseUrl}/api';
  final HybridAuthService _authService = HybridAuthService();

  /// Create a payment intent for an order
  /// Returns the client secret needed for Stripe payment sheet
  Future<Map<String, dynamic>?> createPaymentIntent({
    required String orderId,
    String? authToken, // Made optional, will use token service if null
  }) async {
    try {
      debugPrint('🔐 Creating payment intent for order: $orderId');

      // Get fresh token from hybrid auth service (auto-refreshes if needed)
      final token = authToken ?? await _authService.getToken();

      if (token == null) {
        debugPrint('❌ No authentication token available');
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payment/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'orderId': orderId}),
      );

      debugPrint('📡 Payment intent response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Payment intent created successfully');
          return data['data'];
        } else {
          debugPrint('❌ Payment intent creation failed: ${data['message']}');
          return null;
        }
      } else {
        debugPrint('❌ Payment intent request failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating payment intent: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Initialize and present Stripe payment sheet
  /// Returns true if payment was successful, false otherwise
  Future<bool> presentPaymentSheet({
    required String clientSecret,
    required BuildContext context,
  }) async {
    try {
      debugPrint('💳 Initializing payment sheet...');

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Al Marya Rostery',
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFFA89A6A), // Al Marya gold color
              background: Theme.of(context).scaffoldBackgroundColor,
            ),
            shapes: const PaymentSheetShape(borderRadius: 12, borderWidth: 0),
          ),
        ),
      );

      debugPrint('✅ Payment sheet initialized');

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('✅ Payment completed successfully!');
      return true;
    } on StripeException catch (e) {
      debugPrint('❌ Stripe error: ${e.error.code}');
      debugPrint('Message: ${e.error.message}');

      if (e.error.code == FailureCode.Canceled) {
        debugPrint('ℹ️ Payment was canceled by user');
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Error presenting payment sheet: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Complete payment flow for an order
  /// Creates payment intent and presents payment sheet
  Future<PaymentResult> processPayment({
    required String orderId,
    required String authToken,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Create payment intent
      final paymentData = await createPaymentIntent(
        orderId: orderId,
        authToken: authToken,
      );

      if (paymentData == null) {
        return PaymentResult(
          success: false,
          message: 'Failed to create payment intent',
        );
      }

      final clientSecret = paymentData['clientSecret'] as String?;
      final paymentIntentId = paymentData['paymentIntentId'] as String?;
      final amount = paymentData['amount'] as num?;
      final currency = paymentData['currency'] as String?;

      if (clientSecret == null) {
        return PaymentResult(
          success: false,
          message: 'Invalid payment data received',
        );
      }

      // Step 2: Present payment sheet
      final paymentSuccess = await presentPaymentSheet(
        clientSecret: clientSecret,
        context: context,
      );

      if (paymentSuccess) {
        return PaymentResult(
          success: true,
          message: 'Payment completed successfully',
          paymentIntentId: paymentIntentId,
          amount: amount?.toDouble(),
          currency: currency,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Payment was not completed',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing payment: $e');
      debugPrint('Stack trace: $stackTrace');
      return PaymentResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Process digital wallet payment (Apple Pay / Google Pay)
  Future<PaymentResult> processDigitalWalletPayment({
    required String orderId,
    required String authToken,
    required BuildContext context,
    required bool isApplePay,
  }) async {
    try {
      debugPrint(
        '${isApplePay ? '🍎' : '🤖'} Processing ${isApplePay ? 'Apple' : 'Google'} Pay payment...',
      );

      // Step 1: Create payment intent
      final paymentData = await createPaymentIntent(
        orderId: orderId,
        authToken: authToken,
      );

      if (paymentData == null) {
        return PaymentResult(
          success: false,
          message: 'Failed to create payment intent',
        );
      }

      final clientSecret = paymentData['clientSecret'] as String?;
      final paymentIntentId = paymentData['paymentIntentId'] as String?;
      final amount = paymentData['amount'] as num?;
      final currency = paymentData['currency'] as String?;

      if (clientSecret == null || amount == null || currency == null) {
        return PaymentResult(
          success: false,
          message: 'Invalid payment data received',
        );
      }

      debugPrint(
        '💳 Payment intent created, amount: ${amount / 100} $currency',
      );

      // Step 2: Initialize payment sheet with Apple Pay/Google Pay
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Al Marya Rostery',
          applePay: isApplePay
              ? const PaymentSheetApplePay(merchantCountryCode: 'AE')
              : null,
          googlePay: !isApplePay
              ? const PaymentSheetGooglePay(
                  merchantCountryCode: 'AE',
                  testEnv: true, // Set to false in production
                )
              : null,
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFFA89A6A),
            ),
          ),
        ),
      );

      debugPrint('✅ Payment sheet initialized');

      // Step 3: Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('✅ Payment completed successfully!');

      return PaymentResult(
        success: true,
        message: 'Payment completed successfully',
        paymentIntentId: paymentIntentId,
        amount: amount.toDouble(),
        currency: currency,
      );
    } on StripeException catch (e) {
      debugPrint('❌ Stripe error: ${e.error.code}');
      debugPrint('Message: ${e.error.message}');

      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult(success: false, message: 'Payment was canceled');
      }

      return PaymentResult(
        success: false,
        message: e.error.message ?? 'Payment failed',
      );
    } catch (e) {
      debugPrint('❌ Error processing digital wallet payment: $e');
      return PaymentResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Get payment details for an order
  Future<Map<String, dynamic>?> getPaymentDetails({
    required String orderId,
    required String authToken,
  }) async {
    try {
      debugPrint('📄 Getting payment details for order: $orderId');

      final response = await http.get(
        Uri.parse('$_baseUrl/payment/details/$orderId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Payment details retrieved');
          return data['data'];
        }
      }

      debugPrint('❌ Failed to get payment details: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting payment details: $e');
      return null;
    }
  }
}

/// Result of a payment operation
class PaymentResult {
  final bool success;
  final String message;
  final String? paymentIntentId;
  final double? amount;
  final String? currency;

  PaymentResult({
    required this.success,
    required this.message,
    this.paymentIntentId,
    this.amount,
    this.currency,
  });

  @override
  String toString() {
    return 'PaymentResult(success: $success, message: $message, '
        'paymentIntentId: $paymentIntentId, amount: $amount, currency: $currency)';
  }
}
