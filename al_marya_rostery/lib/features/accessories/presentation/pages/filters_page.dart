import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/accessory_model.dart';
import '../../data/accessory_api_service.dart';

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  final AccessoryApiService _apiService = AccessoryApiService();
  List<Accessory> _filters = [];
  bool _isLoading = true;
  String? _error;
  bool _showProducts = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filters = await _apiService.fetchAccessoriesByType(
        'filter',
        limit: 50,
      );

      setState(() {
        _filters = filters;
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
        title: const Text('Coffee Filters'),
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
                'Shop Now (${_filters.length})',
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
              'Error loading filters',
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
              onPressed: _loadFilters,
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

    if (_filters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Filters Available',
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
                'All Filters (${_filters.length})',
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
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              return _buildFilterCard(_filters[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(Accessory filter) {
    final imageUrl = _getFullImageUrl(filter.primaryImageUrl);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/product-detail', arguments: filter);
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
                            Icons.filter_alt,
                            color: Colors.grey.shade400,
                            size: 50,
                          ),
                        )
                      : Icon(
                          Icons.filter_alt,
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
                      filter.name.en,
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
                            filter.formattedPrice,
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
                            color: filter.stock.isInStock
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            filter.stock.isInStock
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: filter.stock.isInStock
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
              child: Icon(Icons.filter_alt, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),

          // Title and Description
          Text(
            'Coffee Filters',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover our collection of premium coffee filters for clean, pure coffee extraction. ${_filters.isNotEmpty ? "${_filters.length} products available." : ""}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),

          // Filter Types
          _buildFilterTypes(context),

          const SizedBox(height: 24),

          // Filter Shapes & Sizes
          _buildFilterSizesGuide(context),

          const SizedBox(height: 24),

          // Why Filters Matter
          _buildInfoSection(
            context,
            'Why Coffee Filters Matter',
            Icons.info_outline,
            'Quality filters remove sediment and oils while allowing the coffee\'s flavor compounds to pass through, resulting in a cleaner, brighter cup.',
            AppTheme.accentAmber,
          ),

          const SizedBox(height: 24),

          // Filter Tips
          _buildFilterTips(context),

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
                _filters.isEmpty
                    ? 'No Products Available'
                    : 'Shop Coffee Filters (${_filters.length})',
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

  Widget _buildFilterTypes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types of Coffee Filters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Paper Filters
        _buildFilterTypeCard(
          context,
          'Paper Filters',
          'Disposable filters for clean, sediment-free coffee',
          Icons.description,
          AppTheme.primaryBrown,
          [
            'Single-use convenience',
            'Removes oils and sediment',
            'Clean, bright flavor',
            'Various shapes available',
          ],
        ),

        const SizedBox(height: 16),

        // Metal Filters
        _buildFilterTypeCard(
          context,
          'Metal Filters',
          'Reusable filters that allow oils and fine particles',
          Icons.filter_frames,
          AppTheme.accentAmber,
          [
            'Reusable and eco-friendly',
            'Allows coffee oils through',
            'Fuller body coffee',
            'Cost-effective long-term',
          ],
        ),

        const SizedBox(height: 16),

        // Cloth Filters
        _buildFilterTypeCard(
          context,
          'Cloth Filters',
          'Traditional fabric filters for unique flavor profile',
          Icons.dry_cleaning,
          AppTheme.primaryLightBrown,
          [
            'Reusable fabric material',
            'Unique flavor profile',
            'Environmental friendly',
            'Requires special care',
          ],
        ),

        const SizedBox(height: 16),

        // Permanent Filters
        _buildFilterTypeCard(
          context,
          'Permanent Filters',
          'Built-in filters for coffee makers',
          Icons.settings_backup_restore,
          AppTheme.textDark,
          [
            'Built into machine',
            'No replacement needed',
            'Convenient operation',
            'Easy maintenance',
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTypeCard(
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

  Widget _buildFilterSizesGuide(BuildContext context) {
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
              Icon(Icons.crop_free, color: AppTheme.primaryBrown),
              const SizedBox(width: 8),
              Text(
                'Filter Shapes & Sizes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterSizeRow('V60 #1', 'Small', '1-2 cups'),
          _buildFilterSizeRow('V60 #2', 'Medium', '1-4 cups'),
          _buildFilterSizeRow('V60 #3', 'Large', '1-6 cups'),
          _buildFilterSizeRow('Chemex', 'Square', '3-10 cups'),
          _buildFilterSizeRow('Kalita Wave', 'Flat bottom', '1-4 cups'),
          _buildFilterSizeRow('Basket', 'Round', 'Drip machines'),
        ],
      ),
    );
  }

  Widget _buildFilterSizeRow(String type, String shape, String capacity) {
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
              shape,
              style: const TextStyle(
                color: AppTheme.primaryBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              capacity,
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

  Widget _buildFilterTips(BuildContext context) {
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
                'Filter Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Rinse paper filters with hot water before brewing'),
          _buildTip('Use the correct filter size for your brewing device'),
          _buildTip('Store filters in a dry place to prevent moisture'),
          _buildTip('Replace metal filters if they become clogged'),
          _buildTip('Choose filter type based on desired coffee body'),
          _buildTip('Clean reusable filters thoroughly after each use'),
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
