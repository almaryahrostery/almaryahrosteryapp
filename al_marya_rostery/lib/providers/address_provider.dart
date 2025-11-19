import 'package:flutter/material.dart';
import '../models/saved_address.dart';
import '../services/address_service.dart';
import '../core/utils/app_logger.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<SavedAddress> _savedAddresses = [];
  SavedAddress? _selectedAddress;
  SavedAddress? _defaultAddress;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<SavedAddress> get savedAddresses => _savedAddresses;
  SavedAddress? get selectedAddress => _selectedAddress;
  SavedAddress? get defaultAddress => _defaultAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get hasAddresses => _savedAddresses.isNotEmpty;

  // Filtered addresses based on search
  List<SavedAddress> get filteredAddresses {
    if (_searchQuery.isEmpty) {
      return _savedAddresses;
    }

    final query = _searchQuery.toLowerCase();
    return _savedAddresses.where((address) {
      return address.name.toLowerCase().contains(query) ||
          address.fullAddress.toLowerCase().contains(query) ||
          (address.buildingDetails?.toLowerCase().contains(query) ?? false) ||
          (address.landmark?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Initialize the provider
  Future<void> initialize() async {
    await loadSavedAddresses();
    await loadDefaultAddress();
  }

  /// Load all saved addresses
  Future<void> loadSavedAddresses() async {
    try {
      AppLogger.info('[AddressProvider] 🔄 Loading saved addresses...');
      _setLoading(true);
      _clearError();

      _savedAddresses = await _addressService.getSavedAddresses();
      AppLogger.info(
        '[AddressProvider] ✅ Loaded ${_savedAddresses.length} addresses',
      );

      if (_savedAddresses.isNotEmpty) {
        for (var addr in _savedAddresses) {
          AppLogger.debug(
            '[AddressProvider] 📍 Address: ${addr.name} - ${addr.fullAddress}',
          );
        }
      } else {
        AppLogger.warning('[AddressProvider] ⚠️ No addresses found in storage');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('[AddressProvider] ❌ Error loading addresses: $e');
      _setError('Failed to load saved addresses: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load default address
  Future<void> loadDefaultAddress() async {
    try {
      _defaultAddress = await _addressService.getDefaultAddress();

      // If we have a default address and no selected address, use default
      if (_defaultAddress != null && _selectedAddress == null) {
        _selectedAddress = _defaultAddress;
      }

      notifyListeners();
    } catch (e) {
      // Log error loading default address in debug mode only
      assert(() {
        AppLogger.error('loading default address: $e');
        return true;
      }());
    }
  }

  /// Add a new address
  Future<bool> addAddress(SavedAddress address) async {
    try {
      AppLogger.info(
        '[AddressProvider] 💾 Adding new address: ${address.name}',
      );
      _setLoading(true);
      _clearError();

      final success = await _addressService.saveAddress(address);

      if (success) {
        AppLogger.info('[AddressProvider] ✅ Address saved successfully');
        _savedAddresses.add(address);
        _savedAddresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // If this is the first address or marked as default, set as selected
        if (_savedAddresses.length == 1 || address.isDefault) {
          _selectedAddress = address;
          _defaultAddress = address;
        }

        AppLogger.info(
          '[AddressProvider] 📊 Total addresses now: ${_savedAddresses.length}',
        );
        notifyListeners();
        return true;
      } else {
        AppLogger.warning(
          '[AddressProvider] ⚠️ Address save failed - duplicate detected',
        );
        _setError(
          'Address with this name already exists or location is too close to an existing address',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('[AddressProvider] ❌ Error adding address: $e');
      _setError('Failed to save address: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _addressService.deleteAddress(addressId);

      if (success) {
        _savedAddresses.removeWhere((address) => address.id == addressId);

        // If deleted address was selected, clear selection
        if (_selectedAddress?.id == addressId) {
          _selectedAddress = _savedAddresses.isNotEmpty
              ? _savedAddresses.first
              : null;
        }

        // If deleted address was default, clear default
        if (_defaultAddress?.id == addressId) {
          _defaultAddress = _savedAddresses.isNotEmpty
              ? _savedAddresses.first
              : null;
          if (_defaultAddress != null) {
            await _addressService.setDefaultAddress(_defaultAddress!.id);
          }
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _setError('Failed to delete address: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress(SavedAddress address) async {
    try {
      await _addressService.setDefaultAddress(address.id);
      _defaultAddress = address;
      _selectedAddress = address;
      notifyListeners();
    } catch (e) {
      _setError('Failed to set default address: ${e.toString()}');
    }
  }

  /// Select an address (temporary selection)
  void selectAddress(SavedAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Search addresses
  void searchAddresses(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Get display text for selected address
  String getSelectedAddressDisplay() {
    if (_selectedAddress == null) {
      return 'Select delivery location';
    }

    return _selectedAddress!.displayName;
  }

  /// Check if an address is selected
  bool isAddressSelected(SavedAddress address) {
    return _selectedAddress?.id == address.id;
  }

  /// Check if an address is default
  bool isAddressDefault(SavedAddress address) {
    return _defaultAddress?.id == address.id;
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadSavedAddresses();
    await loadDefaultAddress();
  }

  /// Clear all addresses (for testing)
  Future<void> clearAllAddresses() async {
    try {
      _setLoading(true);
      await _addressService.clearAllAddresses();
      _savedAddresses.clear();
      _selectedAddress = null;
      _defaultAddress = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear addresses: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
