import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_address.dart';
import '../services/address_api_service.dart';

class AddressProvider extends ChangeNotifier {
  static const String _boxName = 'user_addresses';
  Box<UserAddress>? _addressBox;
  List<UserAddress> _addresses = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  final AddressApiService _apiService = AddressApiService();

  // Getters
  List<UserAddress> get addresses => _addresses;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserAddress? get defaultAddress {
    try {
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  List<UserAddress> getAddressesByLabel(String label) {
    return _addresses.where((addr) => addr.label == label).toList();
  }

  // Initialize Hive box
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Open the box
      _addressBox = await Hive.openBox<UserAddress>(_boxName);

      // Load addresses
      await loadAddresses();

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize address storage: $e';
      debugPrint('❌ AddressProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all addresses from Hive
  Future<void> loadAddresses() async {
    try {
      if (_addressBox == null) {
        await initialize();
        return;
      }

      _addresses = _addressBox!.values.toList();
      _addresses.sort((a, b) {
        // Default address first
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        // Then by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load addresses: $e';
      debugPrint('❌ Error loading addresses: $e');
      notifyListeners();
    }
  }

  // Add a new address
  Future<bool> addAddress(UserAddress address) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_addressBox == null) {
        await initialize();
      }

      // If this is set as default, remove default from others
      if (address.isDefault) {
        await _clearOtherDefaults();
      }

      // If no addresses exist, make this the default
      if (_addresses.isEmpty) {
        address.isDefault = true;
      }

      // Save to Hive
      await _addressBox!.put(address.id, address);

      // Reload addresses
      await loadAddresses();

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to add address: $e';
      debugPrint('❌ Error adding address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing address
  Future<bool> updateAddress(UserAddress address) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_addressBox == null) {
        await initialize();
      }

      // Update timestamp
      final updatedAddress = address.copyWith(updatedAt: DateTime.now());

      // If this is set as default, remove default from others
      if (updatedAddress.isDefault) {
        await _clearOtherDefaults(exceptId: updatedAddress.id);
      }

      // Save to Hive
      await _addressBox!.put(updatedAddress.id, updatedAddress);

      // Reload addresses
      await loadAddresses();

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to update address: $e';
      debugPrint('❌ Error updating address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an address
  Future<bool> deleteAddress(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_addressBox == null) {
        await initialize();
      }

      final address = _addressBox!.get(id);
      final wasDefault = address?.isDefault ?? false;

      // Delete from Hive
      await _addressBox!.delete(id);

      // If deleted address was default, set another as default
      if (wasDefault && _addresses.length > 1) {
        final firstAddress = _addresses.firstWhere((a) => a.id != id);
        await setDefaultAddress(firstAddress.id);
      }

      // Reload addresses
      await loadAddresses();

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to delete address: $e';
      debugPrint('❌ Error deleting address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set an address as default
  Future<bool> setDefaultAddress(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_addressBox == null) {
        await initialize();
      }

      // Clear all defaults
      await _clearOtherDefaults();

      // Get the address and set as default
      final address = _addressBox!.get(id);
      if (address != null) {
        final updatedAddress = address.copyWith(
          isDefault: true,
          updatedAt: DateTime.now(),
        );
        await _addressBox!.put(id, updatedAddress);
      }

      // Reload addresses
      await loadAddresses();

      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to set default address: $e';
      debugPrint('❌ Error setting default address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear default flag from all addresses except one
  Future<void> _clearOtherDefaults({String? exceptId}) async {
    if (_addressBox == null) return;

    for (var address in _addressBox!.values) {
      if (address.id != exceptId && address.isDefault) {
        final updated = address.copyWith(
          isDefault: false,
          updatedAt: DateTime.now(),
        );
        await _addressBox!.put(address.id, updated);
      }
    }
  }

  // Get address by ID
  UserAddress? getAddressById(String id) {
    try {
      return _addresses.firstWhere((addr) => addr.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if address exists
  bool hasAddresses() {
    return _addresses.isNotEmpty;
  }

  // Get address count
  int get addressCount => _addresses.length;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ===== BACKEND INTEGRATION METHODS =====

  /// Load addresses from backend with optional distance calculation
  Future<void> loadAddressesFromBackend({
    double? latitude,
    double? longitude,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final addresses = await _apiService.getUserAddresses(
        latitude: latitude,
        longitude: longitude,
      );

      _addresses = addresses;
      _addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      // Also sync to local Hive for offline access
      if (_addressBox != null) {
        await _addressBox!.clear();
        for (var address in _addresses) {
          await _addressBox!.put(address.id, address);
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading addresses from backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create address in backend
  Future<bool> createAddressInBackend(UserAddress address) async {
    try {
      _isLoading = true;
      notifyListeners();

      final createdAddress = await _apiService.createAddress(address);
      _addresses.insert(0, createdAddress);

      // Also save to local Hive
      if (_addressBox != null) {
        await _addressBox!.put(createdAddress.id, createdAddress);
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error creating address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update address in backend
  Future<bool> updateAddressInBackend(UserAddress address) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedAddress = await _apiService.updateAddress(address);
      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index != -1) {
        _addresses[index] = updatedAddress;
      }

      // Also update in local Hive
      if (_addressBox != null) {
        await _addressBox!.put(updatedAddress.id, updatedAddress);
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete address from backend
  Future<bool> deleteAddressFromBackend(String addressId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _apiService.deleteAddress(addressId);
      if (success) {
        _addresses.removeWhere((a) => a.id == addressId);

        // Also delete from local Hive
        if (_addressBox != null) {
          await _addressBox!.delete(addressId);
        }
      }

      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error deleting address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set address as default in backend
  Future<bool> setDefaultAddressInBackend(String addressId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.setDefaultAddress(addressId);

      // Update local state
      for (var addr in _addresses) {
        addr.isDefault = addr.id == addressId;
        if (_addressBox != null) {
          await _addressBox!.put(addr.id, addr);
        }
      }

      _addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error setting default address: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Close box when provider is disposed
  @override
  void dispose() {
    _addressBox?.close();
    super.dispose();
  }
}
