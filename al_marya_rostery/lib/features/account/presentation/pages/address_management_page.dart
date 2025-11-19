import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/address_provider.dart';
import '../../../../models/saved_address.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({super.key});

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressProvider>(context, listen: false).loadSavedAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Manage Addresses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppTheme.primaryBrown,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => addressProvider.loadSavedAddresses(),
              ),
            ],
          ),
          body: _buildContent(addressProvider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddAddress(addressProvider),
            backgroundColor: AppTheme.primaryBrown,
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        );
      },
    );
  }

  Widget _buildContent(AddressProvider addressProvider) {
    if (addressProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (addressProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${addressProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => addressProvider.loadSavedAddresses(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final addresses = addressProvider.savedAddresses;

    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No saved addresses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your delivery addresses for faster checkout',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddAddress(addressProvider),
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAddressCard(addresses[index], addressProvider);
      },
    );
  }

  Widget _buildAddressCard(SavedAddress address, AddressProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
            ? BorderSide(color: AppTheme.primaryBrown, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  address.type == AddressType.home
                      ? Icons.home
                      : address.type == AddressType.work
                      ? Icons.work
                      : Icons.location_on,
                  color: AppTheme.primaryBrown,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrown,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address.fullAddress,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (address.buildingDetails != null &&
                address.buildingDetails!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                address.buildingDetails!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
            if (address.landmark != null && address.landmark!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.near_me, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address.landmark!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () => _setAsDefault(address.id, provider),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Set as Default'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBrown,
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _navigateToEditAddress(address, provider),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                TextButton.icon(
                  onPressed: () => _deleteAddress(address.id, provider),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddAddress(AddressProvider provider) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAddressPage()),
    );

    if (result == true) {
      provider.loadSavedAddresses();
    }
  }

  Future<void> _navigateToEditAddress(
    SavedAddress address,
    AddressProvider provider,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressPage(address: address),
      ),
    );

    if (result == true) {
      provider.loadSavedAddresses();
    }
  }

  Future<void> _setAsDefault(String addressId, AddressProvider provider) async {
    try {
      final address = provider.savedAddresses.firstWhere(
        (a) => a.id == addressId,
      );
      await provider.setDefaultAddress(address);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(
    String addressId,
    AddressProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteAddress(addressId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete address: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ==================== Add/Edit Address Page ====================

class AddEditAddressPage extends StatefulWidget {
  final SavedAddress? address;

  const AddEditAddressPage({super.key, this.address});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingDetailsController = TextEditingController();
  final _landmarkController = TextEditingController();

  AddressType _selectedType = AddressType.home;
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddressData();
    }
  }

  void _loadAddressData() {
    final address = widget.address!;
    _nameController.text = address.name;
    _addressController.text = address.fullAddress;
    _buildingDetailsController.text = address.buildingDetails ?? '';
    _landmarkController.text = address.landmark ?? '';
    _selectedType = address.type;
    _isDefault = address.isDefault;
    _latitude = address.latitude;
    _longitude = address.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _buildingDetailsController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Address Name',
                  icon: Icons.label,
                  hint: 'e.g. Home, Office, etc.',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an address name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Address Type
                _buildTypeSelector(),

                const SizedBox(height: 16),

                // Full Address
                _buildTextField(
                  controller: _addressController,
                  label: 'Full Address',
                  icon: Icons.location_on,
                  hint: 'Street, Area, City, Emirates',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the full address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Building Details
                _buildTextField(
                  controller: _buildingDetailsController,
                  label: 'Building/Apartment Details',
                  icon: Icons.apartment,
                  hint: 'e.g. Building 5, Apt 302',
                  required: false,
                ),

                const SizedBox(height: 16),

                // Landmark
                _buildTextField(
                  controller: _landmarkController,
                  label: 'Nearby Landmark',
                  icon: Icons.near_me,
                  hint: 'e.g. Near Mall of Emirates',
                  required: false,
                ),

                const SizedBox(height: 16),

                // Get Current Location Button
                _buildLocationButton(),

                const SizedBox(height: 16),

                // Set as Default
                _buildDefaultCheckbox(),

                const SizedBox(height: 32),

                // Save Button
                _buildSaveButton(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryBrown),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBrown, width: 2),
        ),
      ),
      validator:
          validator ??
          (required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(AddressType.home, Icons.home, 'Home'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(AddressType.work, Icons.work, 'Work'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                AddressType.other,
                Icons.location_on,
                'Other',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(AddressType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBrown.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBrown : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBrown : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.primaryBrown : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
        icon: _isLoadingLocation
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(
          _isLoadingLocation
              ? 'Getting location...'
              : _latitude != null
              ? 'Location Added ✓'
              : 'Use Current Location',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryBrown,
          side: BorderSide(color: AppTheme.primaryBrown),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDefaultCheckbox() {
    return InkWell(
      onTap: () => setState(() => _isDefault = !_isDefault),
      child: Row(
        children: [
          Checkbox(
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value ?? false),
            activeColor: AppTheme.primaryBrown,
          ),
          const Text('Set as default address', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBrown,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditing ? 'Update Address' : 'Save Address',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );

      final address = SavedAddress(
        id:
            widget.address?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        fullAddress: _addressController.text.trim(),
        latitude:
            _latitude ?? 25.2048, // Default to Dubai coordinates if no location
        longitude: _longitude ?? 55.2708,
        type: _selectedType,
        buildingDetails: _buildingDetailsController.text.trim().isEmpty
            ? null
            : _buildingDetailsController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        isDefault: _isDefault,
      );

      await addressProvider.addAddress(address);

      if (_isDefault) {
        await addressProvider.setDefaultAddress(address);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address != null
                  ? 'Address updated successfully!'
                  : 'Address saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
