import 'dart:convert';
import 'dart:math' show sin, cos, atan2, sqrt, pi;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_address.dart';
import '../core/utils/app_logger.dart';
import '../core/services/address_api_service.dart';

class AddressService {
  static const String _addressesKey = 'saved_addresses';
  static const String _defaultAddressKey = 'default_address_id';

  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final AddressApiService _apiService = AddressApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<SavedAddress> _cachedAddresses = [];
  String? _defaultAddressId;
  bool _syncInProgress = false;

  /// Get all saved addresses (syncs with backend)
  Future<List<SavedAddress>> getSavedAddresses() async {
    try {
      // Try to sync with backend first
      await _syncWithBackend();

      // Load from local cache
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      _cachedAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .toList();

      // Sort by creation date, most recent first
      _cachedAddresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.info('Loaded ${_cachedAddresses.length} addresses from local cache', tag: 'AddressService');
      return _cachedAddresses;
    } catch (e) {
      AppLogger.error('Error loading addresses', tag: 'AddressService', error: e);
      return _cachedAddresses; // Return cached addresses if available
    }
  }

  /// Sync addresses with backend
  Future<void> _syncWithBackend() async {
    if (_syncInProgress) return; // Prevent concurrent syncs

    try {
      _syncInProgress = true;

      // Get Firebase token
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('No user logged in, skipping backend sync', tag: 'AddressService');
        return;
      }

      final token = await user.getIdToken();
      if (token == null) {
        AppLogger.warning('No Firebase token available', tag: 'AddressService');
        return;
      }

      // Fetch addresses from backend
      AppLogger.info('Syncing addresses with backend...', tag: 'AddressService');
      final backendAddresses = await _apiService.getAddresses(firebaseToken: token);

      // Update local cache with backend data
      await _updateLocalCache(backendAddresses);

      AppLogger.success('Synced ${backendAddresses.length} addresses from backend', tag: 'AddressService');
    } catch (e) {
      AppLogger.warning('Backend sync failed, using local cache: $e', tag: 'AddressService');
      // Continue with local cache if backend sync fails
    } finally {
      _syncInProgress = false;
    }
  }

  /// Update local cache with backend addresses
  Future<void> _updateLocalCache(List<SavedAddress> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = addresses.map((addr) => jsonEncode(addr.toJson())).toList();
      await prefs.setStringList(_addressesKey, addressesJson);

      // Update default address if exists
      final defaultAddress = addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addresses.isNotEmpty ? addresses.first : SavedAddress(
          id: '',
          name: '',
          fullAddress: '',
          latitude: 0,
          longitude: 0,
          type: AddressType.other,
          createdAt: DateTime.now(),
        ),
      );

      if (defaultAddress.id.isNotEmpty) {
        await prefs.setString(_defaultAddressKey, defaultAddress.id);
        _defaultAddressId = defaultAddress.id;
      }

      _cachedAddresses = addresses;
      AppLogger.info('Updated local cache with ${addresses.length} addresses', tag: 'AddressService');
    } catch (e) {
      AppLogger.error('Error updating local cache', tag: 'AddressService', error: e);
    }
  }

  /// Save a new address (syncs to backend)
  Future<bool> saveAddress(SavedAddress address) async {
    try {
      // Save to backend first
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          try {
            final savedAddress = await _apiService.addAddress(
              address: address,
              firebaseToken: token,
            );

            // Update local cache with backend response
            await _addToLocalCache(savedAddress);
            AppLogger.success('Address saved to backend and local cache', tag: 'AddressService');
            return true;
          } catch (e) {
            AppLogger.warning('Backend save failed, saving locally: $e', tag: 'AddressService');
            // Fall through to local save
          }
        }
      }

      // Fallback: Save to local cache only
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      // Check if address already exists
      final existingAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .toList();

      final isDuplicate = existingAddresses.any(
        (existing) =>
            existing.name.toLowerCase() == address.name.toLowerCase() ||
            (_calculateDistance(
                  existing.latitude,
                  existing.longitude,
                  address.latitude,
                  address.longitude,
                ) <
                0.01), // Within 10 meters
      );

      if (isDuplicate) {
        AppLogger.warning('Duplicate address detected', tag: 'AddressService');
        return false;
      }

      // Add new address locally
      addressesJson.add(jsonEncode(address.toJson()));
      await prefs.setStringList(_addressesKey, addressesJson);

      // Set as default if first address or marked as default
      if (addressesJson.length == 1 || address.isDefault) {
        await setDefaultAddress(address.id);
      }

      // Update cache
      _cachedAddresses.add(address);
      _cachedAddresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.info('Address saved to local cache only', tag: 'AddressService');
      return true;
    } catch (e) {
      AppLogger.error('Error saving address', tag: 'AddressService', error: e);
      return false;
    }
  }

  /// Add address to local cache
  Future<void> _addToLocalCache(SavedAddress address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      // Remove duplicate if exists
      final addresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .where((existing) => existing.id != address.id)
          .toList();

      // Add new address
      addresses.add(address);
      addresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save back to preferences
      final updatedJson = addresses.map((addr) => jsonEncode(addr.toJson())).toList();
      await prefs.setStringList(_addressesKey, updatedJson);

      // Update cache
      _cachedAddresses = addresses;

      // Set as default if marked
      if (address.isDefault) {
        await prefs.setString(_defaultAddressKey, address.id);
        _defaultAddressId = address.id;
      }
    } catch (e) {
      AppLogger.error('Error adding to local cache', tag: 'AddressService', error: e);
    }
  }

  /// Delete an address (syncs with backend)
  Future<bool> deleteAddress(String addressId) async {
    try {
      // Delete from backend first
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          try {
            await _apiService.deleteAddress(
              addressId: addressId,
              firebaseToken: token,
            );
            AppLogger.success('Address deleted from backend', tag: 'AddressService');
          } catch (e) {
            AppLogger.warning('Backend delete failed: $e', tag: 'AddressService');
            // Continue with local delete
          }
        }
      }

      // Delete from local cache
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList(_addressesKey) ?? [];

      final filteredAddresses = addressesJson
          .map((json) => SavedAddress.fromJson(jsonDecode(json)))
          .where((address) => address.id != addressId)
          .map((address) => jsonEncode(address.toJson()))
          .toList();

      await prefs.setStringList(_addressesKey, filteredAddresses);

      // If deleted address was default, clear default
      if (_defaultAddressId == addressId) {
        await prefs.remove(_defaultAddressKey);
        _defaultAddressId = null;
      }

      // Update cache
      _cachedAddresses.removeWhere((address) => address.id == addressId);

      AppLogger.info('Address deleted from local cache', tag: 'AddressService');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting address', tag: 'AddressService', error: e);
      return false;
    }
  }

  /// Set default address (syncs with backend)
  Future<void> setDefaultAddress(String addressId) async {
    try {
      // Set default in backend first
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          try {
            await _apiService.setDefaultAddress(
              addressId: addressId,
              firebaseToken: token,
            );
            AppLogger.success('Default address set in backend', tag: 'AddressService');
          } catch (e) {
            AppLogger.warning('Backend setDefault failed: $e', tag: 'AddressService');
            // Continue with local update
          }
        }
      }

      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultAddressKey, addressId);
      _defaultAddressId = addressId;

      AppLogger.info('Default address set locally: $addressId', tag: 'AddressService');
    } catch (e) {
      AppLogger.error('Error setting default address', tag: 'AddressService', error: e);
    }
  }

  /// Get default address
  Future<SavedAddress?> getDefaultAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _defaultAddressId = prefs.getString(_defaultAddressKey);

      if (_defaultAddressId == null) return null;

      final addresses = await getSavedAddresses();
      return addresses.firstWhere(
        (address) => address.id == _defaultAddressId,
        orElse: () => addresses.isNotEmpty
            ? addresses.first
            : SavedAddress(
                id: '',
                name: '',
                fullAddress: '',
                latitude: 0,
                longitude: 0,
                type: AddressType.other,
                createdAt: DateTime.now(),
              ),
      );
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        AppLogger.error('getting default address: $e');
        return true;
      }());
      return null;
    }
  }

  /// Search addresses by query
  Future<List<SavedAddress>> searchAddresses(String query) async {
    if (query.isEmpty) {
      return await getSavedAddresses();
    }

    final addresses = await getSavedAddresses();
    final searchQuery = query.toLowerCase();

    return addresses.where((address) {
      return address.name.toLowerCase().contains(searchQuery) ||
          address.fullAddress.toLowerCase().contains(searchQuery) ||
          (address.buildingDetails?.toLowerCase().contains(searchQuery) ??
              false) ||
          (address.landmark?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  /// Calculate distance between two coordinates (in kilometers)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Clear all addresses (for testing/reset)
  Future<void> clearAllAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_addressesKey);
      await prefs.remove(_defaultAddressKey);
      _cachedAddresses.clear();
      _defaultAddressId = null;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        AppLogger.error('clearing addresses: $e');
        return true;
      }());
    }
  }
}
