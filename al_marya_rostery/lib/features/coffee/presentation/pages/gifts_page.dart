import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/common/app_drawer.dart';
import '../../../../providers/gift_set_provider.dart';
import '../../../../data/models/gift_set_model.dart';

class GiftsPage extends StatefulWidget {
  const GiftsPage({super.key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch gift sets when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftSetProvider>().fetchGiftSets();
    });
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
            Icon(Icons.card_giftcard, color: Colors.pink, size: 20),
            SizedBox(width: 8),
            Text('Coffee Gifts', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade100, Colors.pink.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.pink, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Perfect Coffee Gifts',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Surprise coffee lovers with our curated gift collections and experiences.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gift Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGiftCard(
              context,
              'Gift Cards',
              'Let them choose their perfect coffee',
              Icons.card_giftcard,
              Colors.pink,
            ),
            const SizedBox(height: 12),
            _buildGiftCard(
              context,
              'Coffee Gift Sets',
              'Curated collections of premium coffees',
              Icons.inventory,
              Colors.brown,
            ),
            const SizedBox(height: 12),
            _buildGiftCard(
              context,
              'Starter Kits',
              'Everything needed to start brewing',
              Icons.play_arrow,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildGiftCard(
              context,
              'Corporate Gifts',
              'Perfect for business relationships',
              Icons.business,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildGiftCard(
              context,
              'Seasonal Collections',
              'Holiday and special occasion gifts',
              Icons.celebration,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade100, Colors.amber.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Coffee Subscription Gifts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Give the gift of fresh coffee delivered monthly. Perfect for coffee enthusiasts!',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/subscription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16),
                        SizedBox(width: 4),
                        Text('Gift Subscription'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Popular Gift Sets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Dynamic Gift Sets from Backend
            Consumer<GiftSetProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.giftSets.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (provider.error != null && provider.giftSets.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(height: 8),
                          const Text('Unable to load gift sets'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => provider.fetchGiftSets(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.giftSets.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No gift sets available at the moment'),
                      ),
                    ),
                  );
                }

                // Show first 3 gift sets
                final displayGiftSets = provider.giftSets.take(3).toList();

                return Column(
                  children: displayGiftSets.map((giftSet) {
                    final locale = Localizations.localeOf(context);
                    final isArabic = locale.languageCode == 'ar';

                    final name = isArabic
                        ? giftSet.name['ar'] ?? giftSet.name['en'] ?? 'Unknown'
                        : giftSet.name['en'] ?? giftSet.name['ar'] ?? 'Unknown';

                    final description = isArabic
                        ? giftSet.description['ar'] ??
                              giftSet.description['en'] ??
                              ''
                        : giftSet.description['en'] ??
                              giftSet.description['ar'] ??
                              '';

                    return Column(
                      children: [
                        _buildPopularGiftCard(
                          context,
                          name,
                          description,
                          giftSet.formattedPrice,
                          giftSet.occasion.replaceFirst(
                            giftSet.occasion[0],
                            giftSet.occasion[0].toUpperCase(),
                          ),
                          giftSet,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/gift-cards'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buy Gift Card',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/gifts/sets'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Shop Gift Sets',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCard(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title'),
              backgroundColor: AppTheme.primaryBrown,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularGiftCard(
    BuildContext context,
    String title,
    String contents,
    String price,
    String note, [
    GiftSetModel? giftSet,
  ]) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contents,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (giftSet != null) {
                      Navigator.pushNamed(
                        context,
                        '/gift-set-detail',
                        arguments: giftSet.id,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing details for $title'),
                          backgroundColor: AppTheme.primaryBrown,
                        ),
                      );
                    }
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (giftSet != null) {
                      // Add gift set to cart logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $title to cart'),
                          backgroundColor: AppTheme.primaryBrown,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $title to cart'),
                          backgroundColor: AppTheme.primaryBrown,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
