import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/coffee_product_model.dart';
import 'write_review_page.dart';
import '../../../../core/utils/app_logger.dart';

/// Product detail page showing full product information with size selection
class ProductDetailPage extends StatefulWidget {
  final CoffeeProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String _selectedSize = '500g'; // Default selected size

  @override
  void initState() {
    super.initState();
    AppLogger.debug(
      '🔍 Product Detail: Received product: ${widget.product.name}',
    );
    AppLogger.debug('🔍 Product Detail: Product ID: ${widget.product.id}');
    AppLogger.debug(
      '🔍 Product Detail: Product type: ${widget.product.runtimeType}',
    );
  }

  // Size options with their prices (multipliers relative to base price per kg)
  // Home page shows per kg price, here we show multiple weight options
  final Map<String, double> _sizeOptions = {
    '250g': 0.6, // 60% of base price per kg (for 250g portion)
    '500g': 1.0, // Base price per kg (for 500g portion)
    '1kg': 1.8, // 180% of base price per kg (for full 1kg)
  };

  double get _selectedPrice =>
      widget.product.price * _sizeOptions[_selectedSize]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
                  ),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryLightBrown.withValues(
                          alpha: 0.2,
                        ),
                        child: const Icon(
                          Icons.coffee,
                          size: 80,
                          color: AppTheme.primaryBrown,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBrown,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Product Info Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name and Origin
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: AppTheme.textLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.product.origin,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.textMedium,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Roast Level Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLightBrown.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.product.roastLevel,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.primaryBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 20,
                            color: AppTheme.accentAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            ' (120 reviews)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textLight),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Size Selection
                      Text(
                        'Select Size',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSizeSelector(),

                      const SizedBox(height: 24),

                      // Price Display
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLightBrown.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Price',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppTheme.textDark),
                            ),
                            Text(
                              '${AppConstants.currencySymbol}${_selectedPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Product Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textMedium,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Add to Cart Button
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final isInCart = cartProvider.items.any(
                            (item) =>
                                item.itemType == CartItemType.coffee &&
                                item.id == widget.product.id &&
                                item.selectedSize == _selectedSize,
                          );

                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (isInCart) {
                                  // Remove specific size from cart
                                  cartProvider.removeItem(widget.product.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${widget.product.name} $_selectedSize removed from cart',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                } else {
                                  // Add to cart with selected size
                                  final cartItem = CartItem.coffee(
                                    product: widget.product,
                                    quantity: 1,
                                    selectedSize: _selectedSize,
                                    price: _selectedPrice,
                                  );
                                  cartProvider.addItemWithSize(cartItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${widget.product.name} $_selectedSize added to cart',
                                      ),
                                      backgroundColor: Colors.green,
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/main-navigation',
                                            arguments: {
                                              'initialIndex': 2,
                                            }, // Cart tab
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                isInCart
                                    ? Icons.remove_shopping_cart
                                    : Icons.add_shopping_cart,
                                size: 24,
                              ),
                              label: Text(
                                isInCart ? 'Remove from Cart' : 'Add to Cart',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isInCart
                                    ? AppTheme.textLight
                                    : AppTheme.primaryBrown,
                                foregroundColor: isInCart
                                    ? AppTheme.textDark
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Write Review Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WriteReviewPage(
                                  productId: widget.product.id,
                                  productName: widget.product.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review),
                          label: Text(
                            'Write a Review',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBrown,
                            side: BorderSide(
                              color: AppTheme.primaryBrown,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating back button
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryBrown,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Row(
      children: _sizeOptions.keys.map((size) {
        final isSelected = _selectedSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedSize = size;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBrown
                    : AppTheme.primaryLightBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBrown
                      : AppTheme.primaryLightBrown.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    size,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstants.currencySymbol}${(widget.product.price * _sizeOptions[size]!).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
