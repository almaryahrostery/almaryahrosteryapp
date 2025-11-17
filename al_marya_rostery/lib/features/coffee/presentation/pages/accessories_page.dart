import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../widgets/common/app_drawer.dart';
import '../../../accessories/data/accessory_model.dart';
import '../../../accessories/data/accessory_api_service.dart';

class AccessoriesPage extends StatefulWidget {
  const AccessoriesPage({super.key});

  @override
  State<AccessoriesPage> createState() => _AccessoriesPageState();
}

class _AccessoriesPageState extends State<AccessoriesPage> {
  final AccessoryApiService _apiService = AccessoryApiService();
  List<Accessory> _featuredAccessories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccessories();
  }

  Future<void> _loadAccessories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final featured = await _apiService.fetchFeaturedAccessories(limit: 5);

      setState(() {
        _featuredAccessories = featured;
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
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.grey, size: 20),
            SizedBox(width: 8),
            Text(
              'Coffee Accessories',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccessories,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading accessories',
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
                    onPressed: _loadAccessories,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade200, Colors.grey.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.settings, color: Colors.grey, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Coffee Equipment',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Everything you need to brew the perfect cup at home. Professional-grade equipment and accessories.',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildAccessoryCard(
                    context,
                    'Brewing Equipment',
                    'French press, pour-over, espresso machines',
                    Icons.coffee_maker,
                    Colors.brown,
                  ),
                  const SizedBox(height: 12),
                  _buildAccessoryCard(
                    context,
                    'Grinders',
                    'Manual and electric coffee grinders',
                    Icons.grain,
                    Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  _buildAccessoryCard(
                    context,
                    'Filters & Papers',
                    'Coffee filters for all brewing methods',
                    Icons.filter_alt,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildAccessoryCard(
                    context,
                    'Scales & Measuring',
                    'Precision scales and measuring tools',
                    Icons.balance,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildAccessoryCard(
                    context,
                    'Storage Solutions',
                    'Airtight containers and storage jars',
                    Icons.inventory_2,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildAccessoryCard(
                    context,
                    'Mugs & Cups',
                    'Premium coffee mugs and cups',
                    Icons.local_cafe,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Featured Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_featuredAccessories.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No featured accessories available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._featuredAccessories.map((accessory) {
                      final imageUrl = _getFullImageUrl(
                        accessory.primaryImageUrl,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stack) => Icon(
                                                  Icons.coffee_maker,
                                                  color: Colors.grey.shade400,
                                                  size: 30,
                                                ),
                                          )
                                        : Icon(
                                            Icons.coffee_maker,
                                            color: Colors.grey.shade400,
                                            size: 30,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        accessory.name.en,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        accessory.description.en,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        accessory.formattedPrice,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.primaryBrown,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          accessory.stockStatus,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: !accessory.stock.isInStock
                                                ? Colors.red
                                                : accessory.stock.quantity <=
                                                      accessory
                                                          .stock
                                                          .lowStockThreshold
                                                ? Colors.orange
                                                : Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: accessory.stock.isInStock
                                      ? () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Added ${accessory.name.en} to cart',
                                              ),
                                              backgroundColor:
                                                  AppTheme.primaryBrown,
                                            ),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_shopping_cart),
                                  color: AppTheme.primaryBrown,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/shop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Shop All Accessories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildAccessoryCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _navigateToCategory(context, title);
        },
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String category) {
    String route;
    switch (category) {
      case 'Mugs & Cups':
        route = '/accessories/mugs';
        break;
      case 'Grinders':
        route = '/accessories/grinders';
        break;
      case 'Filters & Papers':
        route = '/accessories/filters';
        break;
      default:
        // For other categories, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$category page coming soon!'),
            backgroundColor: AppTheme.primaryBrown,
          ),
        );
        return;
    }

    Navigator.pushNamed(context, route);
  }
}
