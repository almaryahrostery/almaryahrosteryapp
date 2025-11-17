import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/features/cart/presentation/providers/cart_provider.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';
import 'package:qahwat_al_emarat/features/address/providers/address_provider.dart';
import 'package:qahwat_al_emarat/core/theme/theme_extensions.dart';

class GuestCheckoutPage extends StatefulWidget {
  const GuestCheckoutPage({super.key});

  @override
  State<GuestCheckoutPage> createState() => _GuestCheckoutPageState();
}

class _GuestCheckoutPageState extends State<GuestCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String _selectedEmirate = 'Dubai';
  final List<String> _emirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-fill user info if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });
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
      if (user.name.isNotEmpty) {
        _nameController.text = user.name;
      }

      // Auto-fill email
      if (user.email.isNotEmpty) {
        _emailController.text = user.email;
      }

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
            orElse: () => 'Dubai',
          );
          setState(() {
            _selectedEmirate = matchingEmirate;
          });
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Checkout'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cart Summary
              _buildCartSummary(cartProvider, colors, theme),
              const SizedBox(height: 32),

              // Guest Information Form
              Text(
                'Delivery Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email_outlined, color: colors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined, color: colors.primary),
                  hintText: '+971 50 123 4567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Street Address *',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: colors.primary,
                  ),
                  hintText: 'Building name, Street name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  if (value.length < 10) {
                    return 'Please enter a complete address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City Field
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City/Area *',
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                    color: colors.primary,
                  ),
                  hintText: 'e.g., Dubai Marina',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city/area';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Emirate Dropdown
              DropdownButtonFormField<String>(
                value: _selectedEmirate,
                decoration: InputDecoration(
                  labelText: 'Emirate *',
                  prefixIcon: Icon(Icons.map_outlined, color: colors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                items: _emirates.map((emirate) {
                  return DropdownMenuItem(value: emirate, child: Text(emirate));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEmirate = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an emirate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Complete Purchase Button
              ElevatedButton(
                onPressed: cartProvider.items.isEmpty ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: colors.primary.withValues(
                    alpha: 0.3,
                  ),
                ),
                child: Text(
                  cartProvider.items.isEmpty
                      ? 'Cart is Empty'
                      : 'Proceed to Payment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Suggestion
              Center(
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('Already have an account? Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'After placing your order, you can create an account to track it!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary(
    CartProvider cartProvider,
    ColorScheme colors,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items (${cartProvider.items.length})',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'AED ${cartProvider.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'AED ${cartProvider.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCheckout() {
    if (_formKey.currentState?.validate() ?? false) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Store guest information
      cartProvider.setGuestInfo(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Navigate to payment page with order data
      final orderData = {
        'shippingAddress': {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'emirate': _selectedEmirate,
        },
        'email': _emailController.text.trim(),
        'items': cartProvider.items,
        'totalAmount': cartProvider.totalPrice,
        'isGuest': true,
      };

      Navigator.of(context).pushNamed('/payment', arguments: orderData);
    }
  }
}
