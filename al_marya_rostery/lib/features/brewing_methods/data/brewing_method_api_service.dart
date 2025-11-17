import 'dart:convert';
import 'package:http/http.dart' as http;
import 'brewing_method_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/hybrid_auth_service.dart';

class BrewingMethodApiService {
  final HybridAuthService _authService = HybridAuthService();
  static String get baseUrl => '${AppConstants.baseUrl}/api';

  /// Fetch all brewing methods
  Future<List<BrewingMethod>> fetchBrewingMethods({
    String? difficulty,
    String? category,
    String? search,
    int? maxTime,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (maxTime != null) queryParams['maxTime'] = maxTime.toString();

      final uri = Uri.parse(
        '$baseUrl/brewing-methods',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> methodsData = data['data'];
          return methodsData
              .map((json) => BrewingMethod.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch brewing methods');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching brewing methods: $e');
    }
  }

  /// Fetch popular brewing methods
  Future<List<BrewingMethod>> fetchPopularBrewingMethods({
    int limit = 6,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/brewing-methods/featured/popular',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> methodsData = data['data'];
          return methodsData
              .map((json) => BrewingMethod.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch popular brewing methods',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching popular brewing methods: $e');
    }
  }

  /// Fetch brewing methods by difficulty
  Future<List<BrewingMethod>> fetchBrewingMethodsByDifficulty(
    String difficulty,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/brewing-methods/difficulty/$difficulty');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> methodsData = data['data'];
          return methodsData
              .map((json) => BrewingMethod.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to fetch brewing methods by difficulty',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching brewing methods by difficulty: $e');
    }
  }

  /// Fetch single brewing method by ID or slug
  Future<BrewingMethod> fetchBrewingMethod(String identifier) async {
    try {
      final uri = Uri.parse('$baseUrl/brewing-methods/$identifier');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BrewingMethod.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch brewing method');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Brewing method not found');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching brewing method: $e');
    }
  }

  /// Rate a brewing method (requires authentication)
  Future<Map<String, double>> rateBrewingMethod(
    String methodId,
    int rating,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/brewing-methods/$methodId/rate');

      final headers = await _authService.getAuthHeaders();

      final body = json.encode({'rating': rating});

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'avgRating': data['data']['avgRating'].toDouble(),
            'totalRatings': data['data']['totalRatings'].toDouble(),
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to rate brewing method');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required to rate brewing methods');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error rating brewing method: $e');
    }
  }

  /// Search brewing methods
  Future<List<BrewingMethod>> searchBrewingMethods(
    String query, {
    String? difficulty,
    int? maxTime,
    String? category,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'search': query,
        'limit': limit.toString(),
      };

      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (maxTime != null) queryParams['maxTime'] = maxTime.toString();
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse(
        '$baseUrl/brewing-methods',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> methodsData = data['data'];
          return methodsData
              .map((json) => BrewingMethod.fromJson(json))
              .toList();
        } else {
          throw Exception(
            data['message'] ?? 'Failed to search brewing methods',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error searching brewing methods: $e');
    }
  }
}
