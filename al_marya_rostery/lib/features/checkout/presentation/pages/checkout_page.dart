import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../address/providers/address_provider.dart';
import '../../../../services/reward_service.dart';
import 'payment_page.dart';

import '../widgets/enhanced_order_summary_widget.dart';
import '../widgets/enhanced_shipping_address_widget.dart';
import '../widgets/google_map_location_picker.dart';

/// CheckoutPage handles the complete checkout process
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Address form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _emirateController = TextEditingController();

  // Location data from Google Maps
  LocationData? _selectedLocation;

  // Delivery options
  String _selectedDeliveryMethod = 'standard';
  DateTime? _selectedDeliveryDate;
  String? _selectedDeliveryTime;

  // Reward Points
  int _availablePoints = 0;
  int _pointsToRedeem = 0;
  double _pointsDiscount = 0.0;
  bool _isLoadingPoints = false;

  final List<String> _deliveryTimes = [
    '9:00 AM - 12:00 PM',
    '12:00 PM - 3:00 PM',
    '3:00 PM - 6:00 PM',
    '6:00 PM - 9:00 PM',
  ];

  final List<String> _emirates = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRewardPoints();
  }

  void _loadUserInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    final user = authProvider.user;
    if (user != null) {
      // Auto-fill user name
      _nameController.text = user.name;

      // Auto-fill phone number if available
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
      }

      // Load default address if available
      final defaultAddress = addressProvider.defaultAddress;
      if (defaultAddress != null) {
        _addressController.text = defaultAddress.formattedAddress;

        // Fill city if available
        if (defaultAddress.city.isNotEmpty) {
          _cityController.text = defaultAddress.city;
        }

        // Fill emirate if available in the emirates list
        if (defaultAddress.area.isNotEmpty) {
          // Try to match area/emirate
          final matchingEmirate = _emirates.firstWhere(
            (e) => e.toLowerCase() == defaultAddress.area.toLowerCase(),
            orElse: () => _emirates.first,
          );
          _emirateController.text = matchingEmirate;
        }

        // Fill phone from address if not already filled from user
        if (_phoneController.text.isEmpty &&
            defaultAddress.contactNumber.isNotEmpty) {
          _phoneController.text = defaultAddress.contactNumber;
        }

        // Fill name from address contact if not already filled
        if (_nameController.text.isEmpty &&
            defaultAddress.contactName.isNotEmpty) {
          _nameController.text = defaultAddress.contactName;
        }
      }
    }
  }

  Future<void> _loadRewardPoints() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      setState(() {
        _isLoadingPoints = true;
      });

      try {
        final points = await RewardService.getUserRewardPoints();
        setState(() {
          _availablePoints = points;
          _isLoadingPoints = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingPoints = false;
        });
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            e,
            onRetry: _loadRewardPoints,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),

              // Checkout Steps
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildShippingStep(cartProvider),
                    _buildDeliveryStep(cartProvider),
                    _buildReviewStep(cartProvider),
                  ],
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigation(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some coffee to start checkout',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceWhite,
      child: Row(
        children: [
          _buildProgressStep(0, 'Shipping', _currentStep >= 0),
          Expanded(child: _buildProgressLine(_currentStep >= 1)),
          _buildProgressStep(1, 'Delivery', _currentStep >= 1),
          Expanded(child: _buildProgressLine(_currentStep >= 2)),
          _buildProgressStep(2, 'Review', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildShippingStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Enhanced shipping address widget with phone validation and Google Maps
            EnhancedShippingAddressWidget(
              nameController: _nameController,
              phoneController: _phoneController,
              addressController: _addressController,
              cityController: _cityController,
              emirateController: _emirateController,
              emirates: _emirates,
              onLocationSelected: (location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Options',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Methods
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Standard Delivery'),
                  subtitle: const Text('3-5 business days - Free'),
                  value: 'standard',
                  selected: _selectedDeliveryMethod == 'standard',
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Express Delivery'),
                  subtitle: const Text('1-2 business days - AED 15'),
                  value: 'express',
                  selected: _selectedDeliveryMethod == 'express',
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Same Day Delivery'),
                  subtitle: const Text('Today - AED 25'),
                  value: 'same_day',
                  selected: _selectedDeliveryMethod == 'same_day',
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryMethod = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Date
          Text(
            'Preferred Delivery Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDeliveryDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.textLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryBrown,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDeliveryDate == null
                        ? 'Select delivery date'
                        : '${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}',
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Time
          Text(
            'Preferred Time Slot',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _deliveryTimes.map((time) {
              final isSelected = _selectedDeliveryTime == time;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDeliveryTime = time;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBrown
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBrown
                          : AppTheme.textLight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Review',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Reward Points Section
          _buildRewardPointsSection(cartProvider),

          const SizedBox(height: 16),

          // Order Summary
          _buildEnhancedOrderSummary(cartProvider),

          const SizedBox(height: 16),

          // Shipping Address Summary
          _buildAddressSummary(),

          const SizedBox(height: 16),

          // Delivery Summary
          _buildDeliverySummary(),
        ],
      ),
    );
  }

  Widget _buildRewardPointsSection(CartProvider cartProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      return const SizedBox.shrink(); // Don't show for guests
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: AppTheme.primaryBrown, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reward Points',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingPoints) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading points...'),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available Points: $_availablePoints'),
                  Text(
                    'Value: AED ${(_availablePoints * 0.05).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              if (_availablePoints > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Redeem Points',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Points Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryBrown,
                    thumbColor: AppTheme.primaryBrown,
                    inactiveTrackColor: AppTheme.textLight,
                  ),
                  child: Slider(
                    value: _pointsToRedeem.toDouble(),
                    min: 0,
                    max: _availablePoints.toDouble(),
                    divisions: _availablePoints > 0 ? _availablePoints : 1,
                    onChanged: (value) {
                      setState(() {
                        _pointsToRedeem = value.round();
                        _pointsDiscount = _pointsToRedeem * 0.05;
                      });
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Redeeming: $_pointsToRedeem points'),
                    Text(
                      'Discount: AED ${_pointsDiscount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.primaryBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedOrderSummary(CartProvider cartProvider) {
    double deliveryFee = 0;
    switch (_selectedDeliveryMethod) {
      case 'express':
        deliveryFee = 15;
        break;
      case 'same_day':
        deliveryFee = 25;
        break;
    }

    return EnhancedOrderSummaryWidget(
      cartProvider: cartProvider,
      deliveryFee: deliveryFee,
      pointsUsed: _pointsToRedeem,
      pointsDiscount: _pointsDiscount,
    );
  }

  Widget _buildAddressSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_nameController.text),
            Text(_phoneController.text),
            Text(_addressController.text),
            Text('${_cityController.text}, ${_emirateController.text}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySummary() {
    String deliveryTitle = '';
    String deliveryPrice = '';

    switch (_selectedDeliveryMethod) {
      case 'standard':
        deliveryTitle = 'Standard Delivery';
        deliveryPrice = 'Free';
        break;
      case 'express':
        deliveryTitle = 'Express Delivery';
        deliveryPrice = 'AED 15';
        break;
      case 'same_day':
        deliveryTitle = 'Same Day Delivery';
        deliveryPrice = 'AED 25';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(deliveryTitle),
                Text(
                  deliveryPrice,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_selectedDeliveryDate != null)
              Text(
                'Date: ${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}',
              ),
            if (_selectedDeliveryTime != null)
              Text('Time: $_selectedDeliveryTime'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(CartProvider cartProvider) {
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryBrown),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _handleNext(cartProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Proceed to Payment' : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext(CartProvider cartProvider) {
    if (_currentStep == 0) {
      // Validate shipping form including phone format and address
      if (_formKey.currentState!.validate()) {
        // Additional validation for phone format
        final phone = _phoneController.text.trim();
        final phoneRegex = RegExp(r'^\+971 5\d{8}$');

        if (phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter your phone number'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (!phoneRegex.hasMatch(phone)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone must be in format +971 5XXXXXXXX'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Validate address is not empty
        final address = _addressController.text.trim();
        if (address.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a delivery address'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      // Validate delivery options
      if (_selectedDeliveryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery date')),
        );
        return;
      }
      if (_selectedDeliveryTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery time')),
        );
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 2) {
      // Proceed to payment
      _proceedToPayment(cartProvider);
    }
  }

  void _proceedToPayment(CartProvider cartProvider) async {
    // Calculate final total including delivery charges and reward discount
    double deliveryFee = 0;
    switch (_selectedDeliveryMethod) {
      case 'express':
        deliveryFee = 15;
        break;
      case 'same_day':
        deliveryFee = 25;
        break;
    }

    final subtotal = cartProvider.totalPrice;
    final totalBeforeDiscount = subtotal + deliveryFee;
    final finalTotal = totalBeforeDiscount - _pointsDiscount;

    // Process reward points redemption if points are being used
    if (_pointsToRedeem > 0) {
      try {
        // Generate a transaction ID for this order
        final transactionId = 'order_${DateTime.now().millisecondsSinceEpoch}';

        await RewardService.redeemPoints(
          pointsToRedeem: _pointsToRedeem,
          totalAmount: finalTotal,
          transactionId: transactionId,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully redeemed $_pointsToRedeem points for AED ${_pointsDiscount.toStringAsFixed(2)} discount!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to redeem points: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    final orderData = {
      'items': cartProvider.items,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'rewardPointsUsed': _pointsToRedeem,
      'pointsDiscount': _pointsDiscount,
      'totalBeforeDiscount': totalBeforeDiscount,
      'total': finalTotal,
      'shippingAddress': {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'emirate': _emirateController.text,
        // Include GPS coordinates if available from Google Maps
        if (_selectedLocation != null)
          'gps': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
      },
      'delivery': {
        'method': _selectedDeliveryMethod,
        'date': _selectedDeliveryDate,
        'time': _selectedDeliveryTime,
      },
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentPage(orderData: orderData),
      ),
    );
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBrown,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emirateController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
