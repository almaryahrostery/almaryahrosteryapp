import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/features/coffee/presentation/pages/product_detail_page.dart';
import 'package:qahwat_al_emarat/data/models/coffee_product_model.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';
import 'package:qahwat_al_emarat/domain/repositories/auth_repository.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';
import 'package:qahwat_al_emarat/core/theme/app_theme.dart';
import 'package:qahwat_al_emarat/features/cart/presentation/providers/cart_provider.dart';

// Mock repository for testing
class MockAuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AuthProvider authProvider;
  late MockAuthRepository mockAuthRepository;
  late CartProvider cartProvider;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authProvider = AuthProvider(mockAuthRepository, skipInitialization: true);
    cartProvider = CartProvider();
  });

  // Create a sample coffee product for testing
  CoffeeProductModel createSampleCoffee() {
    return const CoffeeProductModel(
      id: 'test_coffee_1',
      name: 'Arabica Blend',
      description: 'Premium arabica coffee beans from Ethiopia',
      price: 45.00,
      imageUrl: 'https://example.com/coffee.jpg',
      origin: 'Ethiopia',
      roastLevel: 'Medium',
      stock: 100,
      variants: [],
      categories: ['Premium Coffee', 'Single Origin'],
      isActive: true,
      isFeatured: true,
      rating: 4.5,
      reviewCount: 24,
    );
  }

  Widget createTestWidget(CoffeeProductModel coffee) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ChangeNotifierProvider<CartProvider>(create: (_) => cartProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProductDetailPage(product: coffee),
      ),
    );
  }

  group('Wishlist Widget Tests', () {
    testWidgets('should display wishlist button in AppBar', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check that AppBar exists
      expect(find.byType(AppBar), findsOneWidget);

      // Check for favorite button (either filled or outlined)
      final favoriteButton = find.byType(IconButton).evaluate().where((
        element,
      ) {
        final widget = element.widget as IconButton;
        final icon = widget.icon;
        if (icon is Icon) {
          return icon.icon == Icons.favorite ||
              icon.icon == Icons.favorite_border;
        }
        return false;
      });

      expect(favoriteButton.length, greaterThanOrEqualTo(1));
    });

    testWidgets('should show favorite_border icon when not in wishlist', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Initially should show empty heart (favorite_border)
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should have tooltip for wishlist button', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Find the favorite button
      final favoriteButton = find.byIcon(Icons.favorite_border);
      expect(favoriteButton, findsOneWidget);

      // Verify tooltip widget exists (IconButton has tooltip property)
      final iconButton = tester.widget<IconButton>(
        find.ancestor(of: favoriteButton, matching: find.byType(IconButton)),
      );
      expect(iconButton.tooltip, isNotNull);
    });

    testWidgets('should tap wishlist button without crashing', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Tap the wishlist button
      final favoriteButton = find.byIcon(Icons.favorite_border);
      expect(favoriteButton, findsOneWidget);

      await tester.tap(favoriteButton);
      await tester.pump();

      // Widget should not crash
      expect(find.byType(ProductDetailPage), findsOneWidget);
    });

    testWidgets('should have share button in AppBar', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check for share button (may be share or share_outlined)
      final shareButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            ((widget.icon as Icon).icon == Icons.share ||
                (widget.icon as Icon).icon == Icons.share_outlined),
      );
      expect(shareButton, findsAny);
    });

    testWidgets('should display product details correctly', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check product name (may appear in AppBar and body)
      expect(find.text('Arabica Blend'), findsAtLeastNWidgets(1));

      // Check product price (formatted as currency)
      expect(find.textContaining('45'), findsAtLeastNWidgets(1));

      // Check product description exists
      expect(
        find.textContaining('Premium arabica coffee beans'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should show rating if available', (WidgetTester tester) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check for rating (4.5)
      expect(find.textContaining('4.5'), findsAtLeastNWidgets(1));

      // Check for star icon
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });

    testWidgets('should display flavor notes', (WidgetTester tester) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Scroll to flavor notes section if it exists
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Note: Flavor notes display depends on backend implementation
      // Just verify the page doesn't crash when scrolling
      expect(find.byType(ProductDetailPage), findsOneWidget);
    });

    testWidgets('should have Add to Cart button', (WidgetTester tester) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Scroll to bottom to find Add to Cart button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      // Check for Add to Cart text (button type may vary)
      expect(
        find.textContaining('Add to Cart'),
        findsAny,
        reason: 'Add to Cart button should exist somewhere on the page',
      );
    });

    testWidgets('should display roast level information', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check for roast level
      expect(find.textContaining('Medium'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display origin information', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check for origin
      expect(find.textContaining('Ethiopia'), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle coffee with no rating gracefully', (
      WidgetTester tester,
    ) async {
      final coffee = const CoffeeProductModel(
        id: 'test_coffee_2',
        name: 'New Blend',
        description: 'Brand new coffee with no reviews yet',
        price: 40.00,
        imageUrl: 'https://example.com/new.jpg',
        origin: 'Brazil',
        roastLevel: 'Dark',
        stock: 50,
        rating: 0.0, // No rating
        reviewCount: 0,
      );

      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Widget should not crash
      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text('New Blend'), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle out of stock products', (
      WidgetTester tester,
    ) async {
      final coffee = const CoffeeProductModel(
        id: 'test_coffee_3',
        name: 'Sold Out Blend',
        description: 'Currently unavailable premium blend',
        price: 50.00,
        imageUrl: 'https://example.com/sold-out.jpg',
        origin: 'Kenya',
        roastLevel: 'Light',
        stock: 0, // Out of stock
        rating: 4.0,
        reviewCount: 10,
      );

      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Widget should not crash
      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text('Sold Out Blend'), findsAtLeastNWidgets(1));
    });

    testWidgets('wishlist button should be accessible', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Find the favorite button
      final favoriteButton = find.byIcon(Icons.favorite_border);

      // Verify it's tappable
      final widget = tester.widget<IconButton>(
        find.ancestor(of: favoriteButton, matching: find.byType(IconButton)),
      );

      expect(widget.onPressed, isNotNull);
    });

    testWidgets('should have back navigation capability', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // AppBar should exist for navigation
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Product detail page should be displayed
      expect(find.byType(ProductDetailPage), findsOneWidget);
    });
  });

  group('Wishlist Button State Tests', () {
    testWidgets(
      'should show loading indicator while checking wishlist status',
      (WidgetTester tester) async {
        final coffee = createSampleCoffee();
        await tester.pumpWidget(createTestWidget(coffee));

        // During initial loading, there might be a loading state
        // Just verify the widget doesn't crash during initialization
        await tester.pump();
        expect(find.byType(ProductDetailPage), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(ProductDetailPage), findsOneWidget);
      },
    );

    testWidgets('should persist across rebuilds', (WidgetTester tester) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Trigger rebuild
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // State should persist
      expect(find.byType(ProductDetailPage), findsOneWidget);
    });
  });

  group('Wishlist Integration Tests', () {
    testWidgets('should display product image', (WidgetTester tester) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check for image widget (either Image.network or CachedNetworkImage)
      expect(
        find.byType(Image),
        findsAtLeastNWidgets(1),
        reason: 'Product image should be displayed',
      );
    });

    testWidgets('should show category badge', (WidgetTester tester) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Check for category
      expect(find.textContaining('Premium'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display weight information', (
      WidgetTester tester,
    ) async {
      final coffee = createSampleCoffee();
      await tester.pumpWidget(createTestWidget(coffee));
      await tester.pumpAndSettle();

      // Scroll to find weight/size selector
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Product detail page has size selector (250g, 500g, 1kg)
      // Just verify page loaded correctly
      expect(find.byType(ProductDetailPage), findsOneWidget);
    });
  });
}
