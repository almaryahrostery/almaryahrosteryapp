import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/accessory_model.dart';
import '../../data/accessory_api_service.dart';

class GrindersPage extends StatefulWidget {
  const GrindersPage({super.key});

  @override
  State<GrindersPage> createState() => _GrindersPageState();
}

class _GrindersPageState extends State<GrindersPage> {
  final AccessoryApiService _apiService = AccessoryApiService();
  List<Accessory> _grinders = [];
  bool _isLoading = true;
  String? _error;
  bool _showProducts = false;

  @override
  void initState() {
    super.initState();
    _loadGrinders();
  }

  Future<void> _loadGrinders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final grinders = await _apiService.fetchAccessoriesByType(
        'grinder',
        limit: 50,
      );

      setState(() {
        _grinders = grinders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${AppConstants.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: const Text('Coffee Grinders'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_showProducts)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showProducts = true;
                });
              },
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: Text(
                'Shop Now (${_grinders.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _showProducts ? _buildProductsView() : _buildInfoView(),
    );
  }

  Widget _buildProductsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading grinders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadGrinders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_grinders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Grinders Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back soon for new products',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Grinders (${_grinders.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showProducts = false;
                  });
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('View Guide'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _grinders.length,
            itemBuilder: (context, index) {
              return _buildGrinderCard(_grinders[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrinderCard(Accessory grinder) {
    final imageUrl = _getFullImageUrl(grinder.primaryImageUrl);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/product-detail', arguments: grinder);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Icon(
                            Icons.settings,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        )
                      : Icon(
                          Icons.settings,
                          color: Colors.grey.shade400,
                          size: 50,
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grinder.name.en,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            grinder.formattedPrice,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBrown,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: grinder.stock.isInStock
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            grinder.stock.isInStock
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: grinder.stock.isInStock
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryBrown.withValues(alpha: 0.8),
                  AppTheme.primaryLightBrown,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.settings, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),

          // Title and Description
          Text(
            'Coffee Grinders',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover our collection of premium coffee grinders for the perfect grind every time. ${_grinders.isNotEmpty ? "${_grinders.length} products available." : ""}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),

          // Grinder Types
          _buildGrinderTypes(context),

          const SizedBox(height: 24),

          // Grind Size Guide
          _buildGrindSizeGuide(context),

          const SizedBox(height: 24),

          // Why Grind Size Matters
          _buildInfoSection(
            context,
            'Why Grind Size Matters',
            Icons.info_outline,
            'The grind size affects extraction time and flavor. Different brewing methods require different grind sizes for optimal results.',
            AppTheme.accentAmber,
          ),

          const SizedBox(height: 24),

          // Tips Section
          _buildTipsSection(context),

          const SizedBox(height: 24),

          // Shop Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showProducts = true;
                });
              },
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                _grinders.isEmpty
                    ? 'No Products Available'
                    : 'Shop Coffee Grinders (${_grinders.length})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrinderTypes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types of Coffee Grinders',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Burr Grinders
        _buildGrinderTypeCard(
          context,
          'Burr Grinders',
          'Premium grinding with consistent particle size',
          Icons.precision_manufacturing,
          AppTheme.primaryBrown,
          [
            'Consistent grind size',
            'Better flavor extraction',
            'Adjustable settings',
            'Professional quality',
          ],
        ),

        const SizedBox(height: 16),

        // Blade Grinders
        _buildGrinderTypeCard(
          context,
          'Blade Grinders',
          'Affordable option for everyday brewing',
          Icons.cut,
          AppTheme.accentAmber,
          [
            'Budget-friendly',
            'Compact design',
            'Easy to use',
            'Good for basic needs',
          ],
        ),

        const SizedBox(height: 16),

        // Manual Grinders
        _buildGrinderTypeCard(
          context,
          'Manual Grinders',
          'Portable and precise grinding by hand',
          Icons.fitness_center,
          AppTheme.primaryLightBrown,
          [
            'Portable design',
            'No electricity needed',
            'Precise control',
            'Great for travel',
          ],
        ),
      ],
    );
  }

  Widget _buildGrinderTypeCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> features,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrindSizeGuide(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Grind Size Guide',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGrindSizeRow('Extra Coarse', 'Cold Brew', 'Sea salt'),
          _buildGrindSizeRow('Coarse', 'French Press', 'Breadcrumbs'),
          _buildGrindSizeRow('Medium-Coarse', 'Chemex', 'Coarse sand'),
          _buildGrindSizeRow('Medium', 'Pour Over', 'Table salt'),
          _buildGrindSizeRow('Medium-Fine', 'V60', 'Fine sand'),
          _buildGrindSizeRow('Fine', 'Espresso', 'Powdered sugar'),
          _buildGrindSizeRow('Extra Fine', 'Turkish', 'Flour'),
        ],
      ),
    );
  }

  Widget _buildGrindSizeRow(
    String grindSize,
    String brewMethod,
    String texture,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              grindSize,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              brewMethod,
              style: const TextStyle(
                color: AppTheme.primaryBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              texture,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryLightBrown.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Grinder Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Grind coffee just before brewing for best flavor'),
          _buildTip('Clean your grinder regularly to prevent oil buildup'),
          _buildTip('Invest in a burr grinder for consistent results'),
          _buildTip('Start with manufacturer\'s recommended settings'),
          _buildTip('Adjust grind size based on extraction time'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
