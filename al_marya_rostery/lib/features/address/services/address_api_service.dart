import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/hybrid_auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_address.dart';

class AddressApiService {
  final HybridAuthService _hybridAuth = HybridAuthService();
  final String _baseUrl = '${AppConstants.baseUrl}/api/users/me/addresses';

  /// Get all addresses for the current user
  Future<List<UserAddress>> getUserAddresses({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      // Build query parameters
      String url = _baseUrl;
      if (latitude != null && longitude != null) {
        url += '?latitude=$latitude&longitude=$longitude';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      AppLogger.debug('GET addresses response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final addressesList = data['addresses'] as List;
          return addressesList
              .map((json) => UserAddress.fromJson(json))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load addresses');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load addresses');
      }
    } catch (e) {
      AppLogger.error('Error fetching addresses: $e');
      rethrow;
    }
  }

  /// Get a single address by ID
  Future<UserAddress?> getAddressById(String addressId) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/$addressId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return UserAddress.fromJson(data['address']);
        }
      } else if (response.statusCode == 404) {
        return null;
      }

      return null;
    } catch (e) {
      AppLogger.error('Error fetching address by ID: $e');
      return null;
    }
  }

  /// Create a new address
  Future<UserAddress> createAddress(UserAddress address) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: json.encode(address.toJson()),
      );

      AppLogger.debug('POST address response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return UserAddress.fromJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create address');
        }
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Invalid address data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create address');
      }
    } catch (e) {
      AppLogger.error('Error creating address: $e');
      rethrow;
    }
  }

  /// Update an existing address
  Future<UserAddress> updateAddress(UserAddress address) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/${address.id}'),
        headers: headers,
        body: json.encode(address.toJson()),
      );

      AppLogger.debug('PUT address response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return UserAddress.fromJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update address');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Address not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update address');
      }
    } catch (e) {
      AppLogger.error('Error updating address: $e');
      rethrow;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$_baseUrl/$addressId'),
        headers: headers,
      );

      AppLogger.debug('DELETE address response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else if (response.statusCode == 404) {
        throw Exception('Address not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else {
        return false;
      }
    } catch (e) {
      AppLogger.error('Error deleting address: $e');
      return false;
    }
  }

  /// Set an address as default
  Future<UserAddress> setDefaultAddress(String addressId) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/$addressId/default'),
        headers: headers,
      );

      AppLogger.debug('PUT default address response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return UserAddress.fromJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to set default address');
        }
      } else {
        throw Exception('Failed to set default address');
      }
    } catch (e) {
      AppLogger.error('Error setting default address: $e');
      rethrow;
    }
  }

  /// Verify an address
  Future<UserAddress> verifyAddress(String addressId) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.put(
        Uri.parse('$_baseUrl/$addressId/verify'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return UserAddress.fromJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to verify address');
        }
      } else {
        throw Exception('Failed to verify address');
      }
    } catch (e) {
      AppLogger.error('Error verifying address: $e');
      rethrow;
    }
  }

  /// Find addresses near a location
  Future<List<UserAddress>> findNearbyAddresses({
    required double latitude,
    required double longitude,
    int maxDistance = 5000, // in meters
  }) async {
    try {
      final headers = await _hybridAuth.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/nearby?latitude=$latitude&longitude=$longitude&maxDistance=$maxDistance',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final addressesList = data['addresses'] as List;
          return addressesList
              .map((json) => UserAddress.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      AppLogger.error('Error finding nearby addresses: $e');
      return [];
    }
  }
}
