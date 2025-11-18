import 'package:flutter_test/flutter_test.dart';
import 'package:qahwat_al_emarat/core/constants/app_constants.dart';
import 'package:qahwat_al_emarat/data/datasources/coffee_api_service.dart';

void main() {
  group('Coffee API Connection Tests', () {
    late CoffeeApiService coffeeApiService;

    setUp(() {
      coffeeApiService = CoffeeApiService();
    });

    test('should connect to correct API endpoint', () {
      expect(
        AppConstants.baseUrl,
        equals('https://almaryahrostery.onrender.com'),
      );
      expect(AppConstants.coffeeEndpoint, equals('/api/coffees'));
    });

    test('should be able to create CoffeeApiService', () {
      expect(coffeeApiService, isNotNull);
    });

    // Note: This test would require the backend to be running
    // In a real environment, you'd mock the API calls
    test('should have proper API configuration', () async {
      // Test that our configuration is correct
      expect(AppConstants.baseUrl, contains('almaryahrostery'));
      expect(AppConstants.coffeeEndpoint, startsWith('/api/'));
    });
  });
}
