import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/accessory_model.dart';
import '../../data/accessory_api_service.dart';

class MugsPage extends StatefulWidget {
  const MugsPage({super.key});

  @override
  State<MugsPage> createState() => _MugsPageState();
}

class _MugsPageState extends State<MugsPage> {
  final AccessoryApiService _apiService = AccessoryApiService();
  List<Accessory> _mugs = [];
  bool _isLoading = true;
  String? _error;
  bool _showProducts = false;

  @override
  void initState() {
    super.initState();
    _loadMugs();
  }

  Future<void> _loadMugs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mugs = await _apiService.fetchAccessoriesByType('mug', limit: 50);

      setState(() {
        _mugs = mugs;
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
        title: const Text('Coffee Mugs'),
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
                'Shop Now (${_mugs.length})',
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
              'Error loading mugs',
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
              onPressed: _loadMugs,
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

    if (_mugs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_cafe, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Mugs Available',
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
                'All Mugs (${_mugs.length})',
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
            itemCount: _mugs.length,
            itemBuilder: (context, index) {
              return _buildMugCard(_mugs[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMugCard(Accessory mug) {
    final imageUrl = _getFullImageUrl(mug.primaryImageUrl);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/product-detail', arguments: mug);
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
                            Icons.local_cafe,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        )
                      : Icon(
                          Icons.local_cafe,
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
                      mug.name.en,
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
                            mug.formattedPrice,
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
                            color: mug.stock.isInStock
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            mug.stock.isInStock
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: mug.stock.isInStock
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
              child: Icon(Icons.coffee_outlined, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),

          // Title and Description
          Text(
            'Coffee Mugs & Cups',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover our collection of premium coffee mugs and cups designed to enhance your coffee experience. ${_mugs.isNotEmpty ? "${_mugs.length} products available." : ""}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),

          // Mug Types
          _buildMugTypes(context),

          const SizedBox(height: 24),

          // Size Guide
          _buildSizeGuide(context),

          const SizedBox(height: 24),

          // Material Guide
          _buildMaterialGuide(context),

          const SizedBox(height: 24),

          // Care Instructions
          _buildCareInstructions(context),

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
                _mugs.isEmpty
                    ? 'No Products Available'
                    : 'Shop Coffee Mugs (${_mugs.length})',
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

  Widget _buildMugTypes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types of Coffee Mugs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Espresso Cups
        _buildMugTypeCard(
          context,
          'Espresso Cups',
          '2-3 oz capacity for concentrated coffee shots',
          Icons.local_cafe,
          AppTheme.primaryBrown,
          [
            'Small 2-3 oz size',
            'Thick walls for heat retention',
            'Perfect for espresso shots',
            'Often comes with saucers',
          ],
        ),

        const SizedBox(height: 16),

        // Standard Coffee Mugs
        _buildMugTypeCard(
          context,
          'Standard Coffee Mugs',
          '8-12 oz capacity for regular coffee',
          Icons.coffee,
          AppTheme.accentAmber,
          [
            'Standard 8-12 oz size',
            'Comfortable handle design',
            'Perfect for drip coffee',
            'Versatile for any coffee',
          ],
        ),

        const SizedBox(height: 16),

        // Travel Mugs
        _buildMugTypeCard(
          context,
          'Travel Mugs',
          'Insulated mugs for coffee on the go',
          Icons.commute,
          AppTheme.primaryLightBrown,
          [
            'Spill-proof lids',
            'Insulated design',
            'Car cup holder friendly',
            'Keeps coffee hot for hours',
          ],
        ),

        const SizedBox(height: 16),

        // Large Mugs
        _buildMugTypeCard(
          context,
          'Large Mugs',
          '14-20 oz capacity for coffee enthusiasts',
          Icons.local_drink,
          AppTheme.textDark,
          [
            'Extra large 14-20 oz',
            'Perfect for morning coffee',
            'Great for latte lovers',
            'Fewer refills needed',
          ],
        ),
      ],
    );
  }

  Widget _buildMugTypeCard(
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

  Widget _buildSizeGuide(BuildContext context) {
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
              Icon(Icons.straighten, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Size Guide',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSizeRow('Espresso', '2-3 oz', 'Single/double shot'),
          _buildSizeRow('Demitasse', '3-4 oz', 'Strong coffee'),
          _buildSizeRow('Standard', '8-12 oz', 'Regular coffee'),
          _buildSizeRow('Large', '14-16 oz', 'Morning coffee'),
          _buildSizeRow('Extra Large', '18-20 oz', 'Coffee lovers'),
          _buildSizeRow('Travel', '12-20 oz', 'On-the-go'),
        ],
      ),
    );
  }

  Widget _buildSizeRow(String type, String capacity, String usage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              type,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              capacity,
              style: const TextStyle(
                color: AppTheme.primaryBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              usage,
              style: const TextStyle(color: AppTheme.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialGuide(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: AppTheme.accentAmber),
              const SizedBox(width: 8),
              Text(
                'Material Guide',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMaterialPoint(
            'Ceramic: Excellent heat retention, easy to clean',
          ),
          _buildMaterialPoint(
            'Porcelain: Elegant, non-porous, dishwasher safe',
          ),
          _buildMaterialPoint('Glass: Shows coffee color, heat resistant'),
          _buildMaterialPoint('Stainless Steel: Durable, great for travel'),
          _buildMaterialPoint('Double-wall: Insulated, keeps hands cool'),
        ],
      ),
    );
  }

  Widget _buildMaterialPoint(String point) {
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
              color: AppTheme.accentAmber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              point,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInstructions(BuildContext context) {
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
              Icon(Icons.cleaning_services, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Care Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCarePoint('Wash with warm soapy water after each use'),
          _buildCarePoint('Avoid abrasive cleaners or steel wool'),
          _buildCarePoint('Check if dishwasher safe before using'),
          _buildCarePoint('Dry thoroughly to prevent water spots'),
          _buildCarePoint('Store in a dry place to prevent damage'),
        ],
      ),
    );
  }

  Widget _buildCarePoint(String point) {
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
              point,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
