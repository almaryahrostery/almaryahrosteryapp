import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/config_service.dart';
import '../../../../core/services/auth_token_service.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/services/order_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'order_confirmation_page.dart';

/// PaymentPage handles payment processing for orders
class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PaymentPage({super.key, required this.orderData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod =
      'cash'; // Default to cash since Stripe might not be ready
  bool _isProcessing = false;
  bool _isApplePaySupported = false;
  bool _isGooglePaySupported = false;
  bool _isStripeInitialized = false;

  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  // Cash on delivery
  final _cashNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set digital wallet support based on platform
    _isApplePaySupported = Platform.isIOS;
    _isGooglePaySupported = Platform.isAndroid;

    // Ensure Stripe is initialized for payments
    _initializePaymentSystem();

    if (Platform.isIOS) {
      debugPrint(
        '🍎 Running on iOS - Apple Pay: ✓ Available | Google Pay: ✗ Not Available',
      );
    } else if (Platform.isAndroid) {
      debugPrint(
        '🤖 Running on Android - Google Pay: ✓ Available | Apple Pay: ✗ Not Available',
      );
    } else {
      debugPrint(
        '💻 Running on other platform - Digital wallets not available',
      );
    }
  }

  Future<void> _initializePaymentSystem() async {
    try {
      // First, ensure auth token is fresh
      debugPrint('🔐 Refreshing authentication token...');
      final orderService = OrderService();
      final token = await orderService.authToken;

      if (token == null) {
        throw Exception('Please log in to continue with checkout');
      }

      debugPrint('✅ Auth token refreshed successfully');

      // Then initialize Stripe (optional - only needed for card payments)
      try {
        await ConfigService.ensureStripeInitialized();
        if (mounted) {
          setState(() {
            _isStripeInitialized = true;
          });
        }
        debugPrint('✅ Stripe initialized - card payments available');
      } catch (stripeError) {
        debugPrint('⚠️ Stripe initialization failed: $stripeError');
        debugPrint(
          'ℹ️ Card payments will not be available. Cash on Delivery is still available.',
        );
        if (mounted) {
          setState(() {
            _isStripeInitialized = false;
          });
        }
        // Don't throw - allow cash payments to work
      }
    } catch (e) {
      debugPrint('❌ Payment system initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      rethrow; // Only rethrow if it's an auth error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Methods
                    _buildPaymentMethods(),

                    const SizedBox(height: 24),

                    // Payment Form
                    if (_selectedPaymentMethod == 'card')
                      _buildCardPaymentForm()
                    else if (_selectedPaymentMethod == 'cash')
                      _buildCashOnDeliveryForm()
                    else if (_selectedPaymentMethod == 'apple_pay' ||
                        _selectedPaymentMethod == 'google_pay')
                      _buildDigitalWalletInfo(),

                    const SizedBox(height: 24),

                    // Order Summary
                    _buildOrderSummary(),
                  ],
                ),
              ),
            ),
          ),

          // Payment Button
          _buildPaymentButton(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Credit/Debit Card
        _buildPaymentMethodTile(
          'card',
          'Credit/Debit Card',
          Icons.credit_card,
          'Visa, Mastercard, American Express',
        ),

        // Cash on Delivery
        _buildPaymentMethodTile(
          'cash',
          'Cash on Delivery',
          Icons.money,
          'Pay when your order arrives',
        ),

        // Apple Pay (iOS only)
        if (_isApplePaySupported)
          _buildPaymentMethodTile(
            'apple_pay',
            'Apple Pay',
            Icons.apple,
            'Pay with Touch ID or Face ID',
          ),

        // Google Pay (Android only)
        if (_isGooglePaySupported)
          _buildPaymentMethodTile(
            'google_pay',
            'Google Pay',
            Icons.android,
            'Fast & secure payment',
          ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        selected: _selectedPaymentMethod == value,
        // ignore: deprecated_member_use
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
          });
        },
        title: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBrown : AppTheme.textMedium,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryBrown : AppTheme.textDark,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
        ),
        activeColor: AppTheme.primaryBrown,
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information (Powered by Stripe)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),

        // Card Holder Name
        TextFormField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBrown),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Card Number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Card Number',
            prefixIcon: const Icon(Icons.credit_card),
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBrown),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Please enter valid card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            // Expiry Date
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBrown),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter expiry date';
                  }
                  if (value.length < 5) {
                    return 'Invalid expiry date';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),

            // CVV
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBrown),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter CVV';
                  }
                  if (value.length < 3) {
                    return 'Invalid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Security Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security,
                color: AppTheme.primaryBrown,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your payment information is encrypted and secure',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryBrown),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashOnDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentAmber),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: AppTheme.accentAmber),
                  const SizedBox(width: 8),
                  Text(
                    'Cash on Delivery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You will pay when your order is delivered. Please have the exact amount ready.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Optional note
        TextFormField(
          controller: _cashNoteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Special Instructions (Optional)',
            hintText: 'Any special delivery instructions...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBrown),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalWalletInfo() {
    final isApplePay = _selectedPaymentMethod == 'apple_pay';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBrown.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isApplePay ? Icons.apple : Icons.android,
                size: 64,
                color: AppTheme.primaryBrown,
              ),
              const SizedBox(height: 16),
              Text(
                isApplePay ? 'Apple Pay' : 'Google Pay',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isApplePay
                    ? 'Fast, secure payment with Touch ID or Face ID'
                    : 'Fast, secure payment with your Google account',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your payment is processed securely through Stripe',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = (widget.orderData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final deliveryFee =
        (widget.orderData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    // Support different keys for subscription flow: prefer 'total', then 'totalPerDelivery'
    final total =
        (widget.orderData['total'] as num?)?.toDouble() ??
        (widget.orderData['totalPerDelivery'] as num?)?.toDouble() ??
        (widget.orderData['totalSubscription'] as num?)?.toDouble() ??
        0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(
                  '${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text(
                  deliveryFee == 0
                      ? 'Free'
                      : '${AppConstants.currencySymbol}${deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: deliveryFee == 0 ? AppTheme.accentAmber : null,
                    fontWeight: deliveryFee == 0 ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),

            if (_selectedPaymentMethod == 'cash') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('COD Fee'),
                  Text(
                    '${AppConstants.currencySymbol}5.00',
                    style: const TextStyle(color: AppTheme.textMedium),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${AppConstants.currencySymbol}${(_selectedPaymentMethod == 'cash' ? total + 5 : total).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final total =
        (widget.orderData['total'] as num?)?.toDouble() ??
        (widget.orderData['totalPerDelivery'] as num?)?.toDouble() ??
        (widget.orderData['totalSubscription'] as num?)?.toDouble() ??
        0.0;
    final finalTotal = _selectedPaymentMethod == 'cash' ? total + 5 : total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Pay ${AppConstants.currencySymbol}${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  void _processPayment() async {
    // Validate card form if card payment
    if (_selectedPaymentMethod == 'card' &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Initialize services
      final orderService = OrderService();
      final paymentService = PaymentService();
      final authService = AuthTokenService();

      // Force fresh authentication token before order creation
      debugPrint('🔐 Refreshing authentication token...');
      final token = await authService.getAccessToken(forceRefresh: true);

      if (token == null) {
        // Token refresh failed - guide user to re-login
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          final shouldReLogin = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Session Expired'),
              content: const Text(
                'Your login session has expired. Please log in again to complete your order.\n\n'
                'Don\'t worry - your cart items will be saved!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Log In'),
                ),
              ],
            ),
          );

          if (shouldReLogin == true) {
            // Navigate to login page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
        return;
      }
      debugPrint('✅ Fresh token obtained successfully');

      // Prepare order items
      final items = (widget.orderData['items'] as List).map((item) {
        // Support both domain objects and plain maps passed from different flows
        if (item is Map) {
          final productName = item['name'] ?? item['productName'] ?? '';
          final unitPrice = (item['unitPrice'] ?? item['price'] ?? 0)
              .toDouble();
          return {
            'productId': item['productId'] ?? item['id'],
            'id': item['productId'] ?? item['id'],
            'name': productName,
            'quantity': item['quantity'] ?? 1,
            'price': unitPrice,
            'roastLevel': item['roastLevel'] ?? 'Medium',
            'grindSize': item['grindSize'] ?? 'Whole Bean',
          };
        } else {
          // Assume item is an object with properties
          try {
            final product = item.product;
            return {
              'productId': item.id,
              'id': item.id,
              'name': product.name,
              'quantity': item.quantity,
              'price': product.price,
              'roastLevel': item.roastLevel ?? 'Medium',
              'grindSize': item.grindSize ?? 'Whole Bean',
            };
          } catch (_) {
            // Fallback: stringify
            return {
              'productId': null,
              'id': null,
              'name': item.toString(),
              'quantity': 1,
              'price': 0.0,
              'roastLevel': 'Medium',
              'grindSize': 'Whole Bean',
            };
          }
        }
      }).toList();

      // Get delivery info
      final deliveryInfo =
          widget.orderData['delivery'] as Map<String, dynamic>?;

      // Calculate final total with COD fee
      final total =
          (widget.orderData['total'] as num?)?.toDouble() ??
          (widget.orderData['totalPerDelivery'] as num?)?.toDouble() ??
          (widget.orderData['totalSubscription'] as num?)?.toDouble() ??
          0.0;
      final finalTotal = _selectedPaymentMethod == 'cash' ? total + 5 : total;

      debugPrint('💳 Processing payment: $_selectedPaymentMethod');
      debugPrint('💰 Final total: AED $finalTotal');
      debugPrint('📦 Items to order: ${items.length}');
      debugPrint('🏠 Shipping address: ${widget.orderData['shippingAddress']}');

      // STEP 1: Create order with 'pending' status
      debugPrint('⏳ Creating order on backend...');
      final result = await orderService.createOrder(
        items: items,
        shippingAddress: widget.orderData['shippingAddress'],
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: 'pending', // Always pending initially
        totalAmount: finalTotal,
        deliveryInfo: deliveryInfo,
        specialInstructions: _cashNoteController.text.isNotEmpty
            ? _cashNoteController.text
            : null,
      );

      debugPrint('📊 Order creation result: ${result['success']}');

      if (result['success'] != true) {
        final errorMsg =
            result['message'] ?? result['error'] ?? 'Order creation failed';
        debugPrint('❌ Order creation failed: $errorMsg');
        throw Exception(errorMsg);
      }

      final orderData = result['order'];
      final orderId = orderData['_id'] as String;
      orderData['paymentMethod'] = _selectedPaymentMethod;

      debugPrint('✅ Order created: $orderId');

      // STEP 2: Handle payment based on method
      if (_selectedPaymentMethod == 'card') {
        // Use Stripe for card payments
        debugPrint('💳 Initiating Stripe payment...');

        // Get auth token
        final authToken = await orderService.authToken;
        if (authToken == null) {
          throw Exception('Authentication required. Please login.');
        }

        // Process payment with Stripe
        final paymentResult = await paymentService.processPayment(
          orderId: orderId,
          authToken: authToken,
          context: context,
        );

        if (!paymentResult.success) {
          throw Exception(paymentResult.message);
        }

        debugPrint('✅ Stripe payment successful!');
        debugPrint('💳 Payment Intent ID: ${paymentResult.paymentIntentId}');

        // Add Stripe payment details to order data
        if (paymentResult.paymentIntentId != null) {
          orderData['stripePaymentIntentId'] = paymentResult.paymentIntentId;
        }
      } else if (_selectedPaymentMethod == 'apple_pay' ||
          _selectedPaymentMethod == 'google_pay') {
        // Process Apple Pay or Google Pay
        final isApplePay = _selectedPaymentMethod == 'apple_pay';
        debugPrint(
          '${isApplePay ? '🍎' : '🤖'} Initiating ${isApplePay ? 'Apple' : 'Google'} Pay...',
        );

        // Get auth token
        final authToken = await orderService.authToken;
        if (authToken == null) {
          throw Exception('Authentication required. Please login.');
        }

        // Process digital wallet payment
        final paymentResult = await paymentService.processDigitalWalletPayment(
          orderId: orderId,
          authToken: authToken,
          context: context,
          isApplePay: isApplePay,
        );

        if (!paymentResult.success) {
          throw Exception(paymentResult.message);
        }

        debugPrint('✅ Digital wallet payment successful!');
        debugPrint('💳 Payment Intent ID: ${paymentResult.paymentIntentId}');

        // Add payment details to order data
        if (paymentResult.paymentIntentId != null) {
          orderData['stripePaymentIntentId'] = paymentResult.paymentIntentId;
        }
      } else if (_selectedPaymentMethod == 'cash') {
        // Cash on delivery - order stays pending
        debugPrint('💵 Cash on delivery - order will be paid on delivery');
      }

      // STEP 3: Clear cart and navigate to confirmation
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).clearCart();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(orderData: orderData),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Payment processing error: $e');

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Determine user-friendly error message
        String errorMessage =
            'Unable to process your payment. Please try again.';
        bool showRetry = true;

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('token') ||
            errorStr.contains('session') ||
            errorStr.contains('auth')) {
          errorMessage =
              'Your session has expired. Please log in again to complete your order.';
          showRetry = false;
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorStr.contains('stripe') ||
            errorStr.contains('payment')) {
          errorMessage =
              'Payment processing failed. Please verify your payment details and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: showRetry
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _processPayment,
                  )
                : null,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _cashNoteController.dispose();
    super.dispose();
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.length > 16) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != newText.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.length > 4) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if (i == 1 && newText.length > 2) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
