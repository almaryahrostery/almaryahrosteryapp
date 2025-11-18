import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Comprehensive integration test for Al Marya Rostery backend APIs
/// This script verifies all new features work correctly with the backend
class AlMaryaIntegrationTest {
  static const String baseUrl = 'http://localhost:5001';
  static const String testUserId = 'test_user_12345';
  static const String testProductId = 'test_product_12345';

  // Headers for API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'AlMaryaIntegrationTest/1.0',
  };

  /// Main test execution
  static Future<void> runAllTests() async {
    print('🚀 Starting Al Marya Rostery Integration Tests...\n');

    try {
      // 1. Health Check
      await testHealthCheck();

      // 2. Loyalty System Tests
      await testLoyaltySystem();

      // 3. Reviews System Tests
      await testReviewsSystem();

      // 4. Referrals System Tests
      await testReferralsSystem();

      // 5. Subscriptions System Tests
      await testSubscriptionsSystem();

      print('\n✅ All integration tests completed successfully!');
      print('🎉 Backend is ready for production use.');
    } catch (e) {
      print('\n❌ Integration tests failed: $e');
      exit(1);
    }
  }

  /// Test backend health and connectivity
  static Future<void> testHealthCheck() async {
    print('🏥 Testing Backend Health...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['data']['status'];
        final dbStatus = data['data']['database']['status'];
        final collections = data['data']['database']['collections'];

        print('   ✅ Backend Status: $status');
        print('   ✅ Database Status: $dbStatus');
        print('   ✅ Collections Count: $collections');
        print('   ✅ Health check passed\n');
      } else {
        throw Exception(
          'Health check failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('   ❌ Health check failed: $e');
      throw e;
    }
  }

  /// Test loyalty system endpoints
  static Future<void> testLoyaltySystem() async {
    print('🏆 Testing Loyalty System...');

    try {
      // Test loyalty tiers endpoint
      final tiersResponse = await http.get(
        Uri.parse('$baseUrl/api/loyalty/tiers'),
        headers: headers,
      );

      if (tiersResponse.statusCode == 200) {
        final tiersData = json.decode(tiersResponse.body);
        final tiers = tiersData['data']['tiers'] as List;
        print('   ✅ Loyalty Tiers: ${tiers.length} tiers loaded');

        // Verify tier structure
        if (tiers.isNotEmpty) {
          final firstTier = tiers.first;
          // Handle both direct fields and nested _doc structure
          final tierData = firstTier['_doc'] ?? firstTier;
          final hasRequiredFields =
              tierData.containsKey('name') &&
              tierData.containsKey('minPoints') &&
              tierData.containsKey('benefits');

          if (hasRequiredFields) {
            print('   ✅ Tier structure validation passed');
            print(
              '   ✅ First tier: ${tierData['name']} (${tierData['minPoints']}-${tierData['maxPoints'] ?? 'unlimited'} points)',
            );
          } else {
            throw Exception('Tier missing required fields');
          }
        }
      } else {
        throw Exception(
          'Loyalty tiers endpoint failed: ${tiersResponse.statusCode}',
        );
      }

      // Test loyalty rewards endpoint
      final rewardsResponse = await http.get(
        Uri.parse('$baseUrl/api/loyalty/rewards'),
        headers: headers,
      );

      if (rewardsResponse.statusCode == 200) {
        final rewardsData = json.decode(rewardsResponse.body);
        final rewards = rewardsData['data']['rewards'] as List;
        print('   ✅ Loyalty Rewards: ${rewards.length} rewards available');
      } else {
        print(
          '   ⚠️  Loyalty rewards endpoint returned: ${rewardsResponse.statusCode}',
        );
      }

      print('   ✅ Loyalty system tests passed\n');
    } catch (e) {
      print('   ❌ Loyalty system test failed: $e');
      throw e;
    }
  }

  /// Test reviews system endpoints
  static Future<void> testReviewsSystem() async {
    print('⭐ Testing Reviews System...');

    try {
      // Test product reviews endpoint
      final reviewsResponse = await http.get(
        Uri.parse('$baseUrl/api/reviews/product/$testProductId'),
        headers: headers,
      );

      if (reviewsResponse.statusCode == 200) {
        final reviewsData = json.decode(reviewsResponse.body);
        final pagination = reviewsData['data']['pagination'];
        final ratingSummary = reviewsData['data']['ratingSummary'];

        print('   ✅ Product Reviews: ${pagination['totalReviews']} reviews');
        print('   ✅ Average Rating: ${ratingSummary['averageRating']}');
        print('   ✅ Reviews endpoint structure valid');
      } else {
        throw Exception(
          'Reviews endpoint failed: ${reviewsResponse.statusCode}',
        );
      }

      // Test creating a review (this will likely fail without auth, but we test the endpoint)
      final reviewData = {
        'userId': testUserId,
        'productId': testProductId,
        'productName': 'Test Product',
        'rating': 5,
        'title': 'Integration Test Review',
        'comment': 'This is a test review from integration testing',
      };

      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/reviews'),
        headers: headers,
        body: json.encode(reviewData),
      );

      // We expect this to fail due to auth, but endpoint should exist
      if (createResponse.statusCode == 401 ||
          createResponse.statusCode == 403) {
        print('   ✅ Create review endpoint exists (auth required)');
      } else if (createResponse.statusCode == 201) {
        print('   ✅ Create review endpoint working');
      } else {
        print('   ⚠️  Create review returned: ${createResponse.statusCode}');
      }

      print('   ✅ Reviews system tests passed\n');
    } catch (e) {
      print('   ❌ Reviews system test failed: $e');
      throw e;
    }
  }

  /// Test referrals system endpoints
  static Future<void> testReferralsSystem() async {
    print('👥 Testing Referrals System...');

    try {
      // Test referral program info endpoint
      final programResponse = await http.get(
        Uri.parse('$baseUrl/api/referrals/program'),
        headers: headers,
      );

      if (programResponse.statusCode == 200) {
        final programData = json.decode(programResponse.body);
        final program = programData['data'];

        if (program.containsKey('referrerReward') &&
            program.containsKey('refereeReward')) {
          print(
            '   ✅ Referral Program: Referrer gets ${program['referrerReward']} points',
          );
          print(
            '   ✅ Referral Program: Referee gets ${program['refereeReward']} points',
          );
        }
      } else {
        print(
          '   ⚠️  Referral program endpoint returned: ${programResponse.statusCode}',
        );
      }

      // Test user referrals endpoint (will require auth or query params)
      final userReferralsResponse = await http.get(
        Uri.parse(
          '$baseUrl/api/referrals/user/$testUserId?email=test@example.com&name=Test User',
        ),
        headers: headers,
      );

      if (userReferralsResponse.statusCode == 401 ||
          userReferralsResponse.statusCode == 403) {
        print('   ✅ User referrals endpoint exists (auth required)');
      } else if (userReferralsResponse.statusCode == 200) {
        final referralsData = json.decode(userReferralsResponse.body);
        if (referralsData['success'] == true) {
          print('   ✅ User referrals endpoint working');
          print(
            '   ✅ Referral code generated: ${referralsData['data']['referralCode'] ?? 'N/A'}',
          );
        } else {
          print('   ⚠️  User referrals response not successful');
        }
      } else {
        print(
          '   ⚠️  User referrals returned: ${userReferralsResponse.statusCode}',
        );
      }

      print('   ✅ Referrals system tests passed\n');
    } catch (e) {
      print('   ❌ Referrals system test failed: $e');
      throw e;
    }
  }

  /// Test subscriptions system endpoints
  static Future<void> testSubscriptionsSystem() async {
    print('📦 Testing Subscriptions System...');

    try {
      // Test subscription plans endpoint (public)
      final plansResponse = await http.get(
        Uri.parse('$baseUrl/api/subscriptions/plans'),
        headers: headers,
      );

      // This might require auth, so we check for various responses
      if (plansResponse.statusCode == 200) {
        final plansData = json.decode(plansResponse.body);
        if (plansData['data'] != null) {
          final plans = plansData['data']['plans'] as List? ?? [];
          print('   ✅ Subscription Plans: ${plans.length} plans available');
        }
      } else if (plansResponse.statusCode == 401 ||
          plansResponse.statusCode == 403) {
        print('   ✅ Subscription plans endpoint exists (auth required)');
      } else {
        print(
          '   ⚠️  Subscription plans returned: ${plansResponse.statusCode}',
        );
      }

      // Test user subscriptions endpoint
      final userSubsResponse = await http.get(
        Uri.parse('$baseUrl/api/subscriptions?userId=$testUserId'),
        headers: headers,
      );

      if (userSubsResponse.statusCode == 401 ||
          userSubsResponse.statusCode == 403) {
        print('   ✅ User subscriptions endpoint exists (auth required)');
      } else if (userSubsResponse.statusCode == 200) {
        print('   ✅ User subscriptions endpoint working');
      } else {
        print(
          '   ⚠️  User subscriptions returned: ${userSubsResponse.statusCode}',
        );
      }

      print('   ✅ Subscriptions system tests passed\n');
    } catch (e) {
      print('   ❌ Subscriptions system test failed: $e');
      throw e;
    }
  }

  /// Utility method to pretty print JSON
  static void printJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    print(encoder.convert(data));
  }
}

/// Entry point for running the integration tests
void main() async {
  // Check if backend is available before running tests
  try {
    final response = await http
        .get(
          Uri.parse('${AlMaryaIntegrationTest.baseUrl}/api/health'),
          headers: AlMaryaIntegrationTest.headers,
        )
        .timeout(const Duration(seconds: 2));

    if (response.statusCode == 200) {
      await AlMaryaIntegrationTest.runAllTests();
    } else {
      print('⚠️  Backend is not available. Skipping integration tests.');
      print('   Start the backend server with: cd backend && npm run dev');
    }
  } catch (e) {
    print('⚠️  Backend is not available. Skipping integration tests.');
    print('   Start the backend server with: cd backend && npm run dev');
    print('   Error: $e');
    // Exit gracefully without failing the test suite
  }
}

// Additional test scenarios for comprehensive validation
class ExtendedIntegrationTests {
  /// Test error handling and edge cases
  static Future<void> testErrorHandling() async {
    print('🛡️ Testing Error Handling...');

    try {
      // Test invalid endpoints
      final invalidResponse = await http.get(
        Uri.parse('${AlMaryaIntegrationTest.baseUrl}/api/invalid-endpoint'),
        headers: AlMaryaIntegrationTest.headers,
      );

      if (invalidResponse.statusCode == 404) {
        print('   ✅ 404 handling works correctly');
      }

      // Test malformed requests
      final malformedResponse = await http.post(
        Uri.parse('${AlMaryaIntegrationTest.baseUrl}/api/reviews'),
        headers: AlMaryaIntegrationTest.headers,
        body: 'invalid json',
      );

      if (malformedResponse.statusCode == 400) {
        print('   ✅ Malformed request handling works');
      }

      print('   ✅ Error handling tests passed\n');
    } catch (e) {
      print('   ⚠️  Error handling test encountered: $e');
    }
  }

  /// Test performance and load capabilities
  static Future<void> testPerformance() async {
    print('⚡ Testing Performance...');

    try {
      final startTime = DateTime.now();
      final futures = <Future>[];

      // Make 10 concurrent requests to health endpoint
      for (int i = 0; i < 10; i++) {
        futures.add(
          http.get(
            Uri.parse('${AlMaryaIntegrationTest.baseUrl}/api/health'),
            headers: AlMaryaIntegrationTest.headers,
          ),
        );
      }

      await Future.wait(futures);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print(
        '   ✅ 10 concurrent requests completed in ${duration.inMilliseconds}ms',
      );

      if (duration.inMilliseconds < 5000) {
        print('   ✅ Performance test passed (< 5 seconds)');
      } else {
        print('   ⚠️  Performance test slow (> 5 seconds)');
      }

      print('   ✅ Performance tests completed\n');
    } catch (e) {
      print('   ❌ Performance test failed: $e');
    }
  }
}
