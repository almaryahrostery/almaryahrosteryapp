import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/common/app_drawer.dart';
import '../../../../data/datasources/remote/subscriptions_api_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionsApiService _subscriptionsApi = SubscriptionsApiService();
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
  }

  Future<void> _loadSubscriptionPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Loading subscription plans...');
      final plans = await _subscriptionsApi.getSubscriptionPlans();
      print('📦 Received ${plans.length} plans from API');
      print('📋 Plans data: $plans');

      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
        print(
          '✅ State updated - _plans.length: ${_plans.length}, _isLoading: $_isLoading, _error: $_error',
        );
      }
    } catch (e) {
      print('❌ Error loading plans: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              'Coffee Subscription',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.star, color: Colors.amber, size: 20),
          ],
        ),
        elevation: 2,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBrown, AppTheme.primaryLightBrown],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Premium Coffee Subscription',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Fresh coffee delivered to your door every month. Never run out of your favorite brew!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subscription Plans
            const Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Loading state
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ),

            // Error state
            if (_error != null && !_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load subscription plans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubscriptionPlans,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBrown,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty state
            if (!_isLoading && _error == null && _plans.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No subscription plans available at the moment',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Display plans from backend
            if (!_isLoading && _error == null && _plans.isNotEmpty)
              ..._plans.map((plan) {
                final isPopular =
                    plan['isPopular'] == true ||
                    plan['name']?.toLowerCase().contains('premium') == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlanCard(
                    plan['name'] ?? 'Unknown Plan',
                    plan['description'] ?? 'No description',
                    'AED ${(plan['price'] ?? 0).toStringAsFixed(2)}/${plan['billingCycle'] ?? 'month'}',
                    isPopular,
                    context,
                    plan,
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Benefits Section
            const Text(
              'Subscription Benefits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildBenefit(
                      Icons.local_shipping,
                      'Free Delivery',
                      'No delivery charges on subscription orders',
                    ),
                    const SizedBox(height: 16),
                    _buildBenefit(
                      Icons.discount,
                      '15% Savings',
                      'Save 15% compared to regular prices',
                    ),
                    const SizedBox(height: 16),
                    _buildBenefit(
                      Icons.schedule,
                      'Flexible Schedule',
                      'Pause, skip, or modify anytime',
                    ),
                    const SizedBox(height: 16),
                    _buildBenefit(
                      Icons.star,
                      'Exclusive Access',
                      'First access to new blends and limited editions',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // CTA Button - only show if plans loaded
            if (!_isLoading && _error == null && _plans.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/subscriptions');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'View My Subscriptions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.star, size: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    String description,
    String price,
    bool isPopular,
    BuildContext context,
    Map<String, dynamic> planData,
  ) {
    return Card(
      elevation: isPopular ? 8 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isPopular ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPopular
                          ? Colors.amber.shade700
                          : AppTheme.primaryBrown,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to subscription management with selected plan
                      Navigator.pushNamed(
                        context,
                        '/subscriptions',
                        arguments: planData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? Colors.amber
                          : AppTheme.primaryBrown,
                      foregroundColor: isPopular ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.amber.shade700, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
