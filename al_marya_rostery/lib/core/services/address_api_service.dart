import 'dart:convert';
import '../../models/saved_address.dart';
import '../network/api_client.dart';
import '../utils/app_logger.dart';

class AddressApiService {
  final ApiClient _client = ApiClient();

  /// Get all addresses for current user
  Future<List<SavedAddress>> getAddresses({required String firebaseToken}) async {
    try {
      AppLogger.network('Fetching user addresses...', tag: 'AddressAPI');

      _client.setAuthToken(firebaseToken);
      final response = await _client.get('/users/me/addresses');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List<dynamic> addressesJson = data['addresses'] ?? [];
          final addresses = addressesJson
              .map((json) => SavedAddress.fromBackendJson(json))
              .toList();

          AppLogger.success(
            'Fetched ${addresses.length} addresses',
            tag: 'AddressAPI',
          );
          return addresses;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch addresses');
        }
      } else {
        _handleHttpError(response);
        return [];
      }
    } catch (e) {
      AppLogger.error('Error fetching addresses', tag: 'AddressAPI', error: e);
      rethrow;
    }
  }

  /// Add new address
  Future<SavedAddress> addAddress({
    required SavedAddress address,
    required String firebaseToken,
  }) async {
    try {
      AppLogger.network('Adding new address: ${address.name}', tag: 'AddressAPI');

      _client.setAuthToken(firebaseToken);
      final response = await _client.post(
        '/users/me/addresses',
        body: {
          'name': address.name,
          'fullAddress': address.fullAddress,
          'latitude': address.latitude,
          'longitude': address.longitude,
          'type': address.type.toString().split('.').last,
          'buildingDetails': address.buildingDetails,
          'landmark': address.landmark,
          'isDefault': address.isDefault,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          AppLogger.success('Address added successfully', tag: 'AddressAPI');
          return SavedAddress.fromBackendJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to add address');
        }
      } else {
        _handleHttpError(response);
        throw Exception('Failed to add address');
      }
    } catch (e) {
      AppLogger.error('Error adding address', tag: 'AddressAPI', error: e);
      rethrow;
    }
  }

  /// Update existing address
  Future<SavedAddress> updateAddress({
    required String addressId,
    required SavedAddress address,
    required String firebaseToken,
  }) async {
    try {
      AppLogger.network('Updating address: $addressId', tag: 'AddressAPI');

      _client.setAuthToken(firebaseToken);
      final response = await _client.put(
        '/users/me/addresses/$addressId',
        body: {
          'name': address.name,
          'fullAddress': address.fullAddress,
          'latitude': address.latitude,
          'longitude': address.longitude,
          'type': address.type.toString().split('.').last,
          'buildingDetails': address.buildingDetails,
          'landmark': address.landmark,
          'isDefault': address.isDefault,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          AppLogger.success('Address updated successfully', tag: 'AddressAPI');
          return SavedAddress.fromBackendJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update address');
        }
      } else {
        _handleHttpError(response);
        throw Exception('Failed to update address');
      }
    } catch (e) {
      AppLogger.error('Error updating address', tag: 'AddressAPI', error: e);
      rethrow;
    }
  }

  /// Delete address
  Future<void> deleteAddress({
    required String addressId,
    required String firebaseToken,
  }) async {
    try {
      AppLogger.network('Deleting address: $addressId', tag: 'AddressAPI');

      _client.setAuthToken(firebaseToken);
      final response = await _client.delete('/users/me/addresses/$addressId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          AppLogger.success('Address deleted successfully', tag: 'AddressAPI');
        } else {
          throw Exception(data['message'] ?? 'Failed to delete address');
        }
      } else {
        _handleHttpError(response);
      }
    } catch (e) {
      AppLogger.error('Error deleting address', tag: 'AddressAPI', error: e);
      rethrow;
    }
  }

  /// Set default address
  Future<SavedAddress> setDefaultAddress({
    required String addressId,
    required String firebaseToken,
  }) async {
    try {
      AppLogger.network('Setting default address: $addressId', tag: 'AddressAPI');

      _client.setAuthToken(firebaseToken);
      final response = await _client.put('/users/me/addresses/$addressId/default');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          AppLogger.success('Default address set successfully', tag: 'AddressAPI');
          return SavedAddress.fromBackendJson(data['address']);
        } else {
          throw Exception(data['message'] ?? 'Failed to set default address');
        }
      } else {
        _handleHttpError(response);
        throw Exception('Failed to set default address');
      }
    } catch (e) {
      AppLogger.error('Error setting default address', tag: 'AddressAPI', error: e);
      rethrow;
    }
  }

  void _handleHttpError(response) {
    final statusCode = response.statusCode;
    if (statusCode == 401) {
      throw Exception('Authentication failed. Please sign in again.');
    } else if (statusCode == 404) {
      throw Exception('Address not found.');
    } else if (statusCode == 400) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Invalid request';
        throw Exception(message);
      } catch (e) {
        throw Exception('Invalid request');
      }
    } else {
      throw Exception('Server error: HTTP $statusCode');
    }
  }
}
