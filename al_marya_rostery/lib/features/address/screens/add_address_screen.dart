import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/user_address.dart';
import '../providers/address_provider.dart';
import 'map_picker_screen.dart';

class AddAddressScreen extends StatefulWidget {
  final UserAddress? existingAddress;
  final bool isEditMode;

  const AddAddressScreen({
    super.key,
    this.existingAddress,
    this.isEditMode = false,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Form controllers
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _directionsController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // State variables
  String _selectedLabel = AddressLabel.home;
  LatLng? _selectedLocation;
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set initial tab based on label
    if (widget.existingAddress != null) {
      final index = AddressLabel.all.indexOf(widget.existingAddress!.label);
      _tabController.index = index >= 0 ? index : 0;
    }

    // Populate form if editing
    if (widget.existingAddress != null) {
      _populateForm(widget.existingAddress!);
    }

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedLabel = AddressLabel.all[_tabController.index];
        });
      }
    });
  }

  void _populateForm(UserAddress address) {
    _streetController.text = address.street;
    _buildingController.text = address.building;
    _apartmentController.text = address.apartment;
    _directionsController.text = address.directions;
    _nicknameController.text = address.nickname;
    _receiverNameController.text = address.receiverName;
    _phoneController.text = address.phoneNumber;
    _selectedLabel = address.label;
    _selectedLocation = LatLng(address.latitude, address.longitude);
    _isDefault = address.isDefault;
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialPosition: _selectedLocation,
          initialAddress: _streetController.text.isEmpty
              ? null
              : _streetController.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['position'] as LatLng;
        if (_streetController.text.isEmpty) {
          _streetController.text = result['address'] as String;
        }
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      _showErrorDialog('Please select a location on the map');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final addressProvider = context.read<AddressProvider>();

      final address = UserAddress(
        id: widget.existingAddress?.id,
        label: _selectedLabel,
        street: _streetController.text.trim(),
        building: _buildingController.text.trim(),
        apartment: _apartmentController.text.trim(),
        directions: _directionsController.text.trim(),
        nickname: _nicknameController.text.trim(),
        receiverName: _receiverNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        isDefault: _isDefault,
      );

      bool success;
      if (widget.isEditMode && widget.existingAddress != null) {
        success = await addressProvider.updateAddressInBackend(address);
      } else {
        success = await addressProvider.createAddressInBackend(address);
      }

      if (success && mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackbar(
          widget.isEditMode
              ? 'Address updated successfully'
              : 'Address added successfully',
        );
      } else if (mounted) {
        _showErrorDialog(addressProvider.error ?? 'Failed to save address');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    _directionsController.dispose();
    _nicknameController.dispose();
    _receiverNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Address' : 'Add New Address'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.work), text: 'Work'),
            Tab(icon: Icon(Icons.location_on), text: 'Other'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Map location selector
            _buildLocationSelector(theme, isDark),
            const SizedBox(height: 24),

            // Street address
            _buildTextField(
              controller: _streetController,
              label: 'Street Address *',
              hint: 'e.g., King Fahd Road',
              icon: Icons.location_on_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Street address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Building/Cluster
            _buildTextField(
              controller: _buildingController,
              label: 'Building / Cluster Name',
              hint: 'e.g., Al Nakheel Tower',
              icon: Icons.apartment_outlined,
            ),
            const SizedBox(height: 16),

            // Apartment/Floor/Villa
            _buildTextField(
              controller: _apartmentController,
              label: 'Apartment / Floor / Villa No.',
              hint: 'e.g., Apt 405, 4th Floor',
              icon: Icons.door_front_door_outlined,
            ),
            const SizedBox(height: 16),

            // Directions (optional)
            _buildTextField(
              controller: _directionsController,
              label: 'Directions (Optional)',
              hint: 'e.g., Near the green gate',
              icon: Icons.directions_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Nickname (optional)
            _buildTextField(
              controller: _nicknameController,
              label: 'Address Nickname (Optional)',
              hint: 'e.g., My Home',
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 24),

            // Receiver info section
            Text(
              'Receiver Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Receiver name
            _buildTextField(
              controller: _receiverNameController,
              label: 'Receiver Name *',
              hint: 'Full name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Receiver name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone number
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number *',
              hint: '+966 5XX XXX XXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length < 9) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Set as default checkbox
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                title: const Text('Set as default address'),
                subtitle: const Text('Use this address for all future orders'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                activeColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditMode ? 'Update Address' : 'Save Address',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: _pickLocationOnMap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedLocation != null
                ? theme.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map_outlined, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  _selectedLocation != null
                      ? 'Location Selected'
                      : 'Select Location on Map *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.primaryColor,
                ),
              ],
            ),
            if (_selectedLocation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }
}
