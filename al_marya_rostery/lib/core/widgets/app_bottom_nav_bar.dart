import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../theme/app_theme.dart';

/// Reusable bottom navigation bar component
/// Shows Home, Rewards, Cart, Profile tabs
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNavBar({super.key, this.currentIndex = -1, this.onTap});

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
    } else {
      // Default navigation behavior
      switch (index) {
        case 0: // Home
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          break;
        case 1: // Rewards
          Navigator.pushNamed(context, '/rewards');
          break;
        case 2: // Cart
          Navigator.pushNamed(context, '/cart');
          break;
        case 3: // Profile
          Navigator.pushNamed(context, '/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex >= 0 ? currentIndex : 0,
            onTap: (index) => _handleTap(context, index),
            selectedItemColor: AppTheme.primaryBrown,
            unselectedItemColor: AppTheme.textMedium,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.stars_outlined),
                activeIcon: Icon(Icons.stars),
                label: 'Rewards',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cartProvider.items.isNotEmpty)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrown,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cartProvider.items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartProvider.items.isNotEmpty)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrown,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cartProvider.items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
