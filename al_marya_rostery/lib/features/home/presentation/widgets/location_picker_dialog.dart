import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/location_provider.dart';
import '../../../../models/saved_address.dart';
import '../../../account/presentation/pages/address_management_page.dart';

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  String _selectedLocationType = 'current'; // current, home, work, other
  SavedAddress? _selectedAddress;

  // No mock addresses - get from actual user provider/address service
  final List<SavedAddress> _savedAddresses = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Choose Delivery Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Option
                    _buildLocationOption(
                      'current',
                      'Use Current Location',
                      'Detect my location automatically',
                      Icons.my_location,
                      Colors.blue,
                    ),

                    const SizedBox(height: 16),

                    // Saved Addresses Section
                    const Text(
                      'Saved Addresses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Home Address
                    if (_getAddressByTitle('Home') != null)
                      _buildAddressOption(_getAddressByTitle('Home')!),

                    const SizedBox(height: 12),

                    // Work Address
                    if (_getAddressByTitle('Work') != null)
                      _buildAddressOption(_getAddressByTitle('Work')!),

                    const SizedBox(height: 12),

                    // Other addresses
                    ..._savedAddresses
                        .where(
                          (addr) => addr.name != 'Home' && addr.name != 'Work',
                        )
                        .map(
                          (addr) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAddressOption(addr),
                          ),
                        ),

                    const SizedBox(height: 16),

                    // Add New Address Button
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddEditAddressPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: AppTheme.primaryBrown),
                      label: const Text(
                        'Add New Address',
                        style: TextStyle(color: AppTheme.primaryBrown),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryBrown),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.primaryBrown),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyLocationSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    final isSelected = _selectedLocationType == value;

    return InkWell(
      onTap: () => setState(() => _selectedLocationType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryBrown : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primaryBrown.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryBrown
                          : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryBrown,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressOption(SavedAddress address) {
    final isSelected =
        _selectedLocationType == 'address' &&
        _selectedAddress?.id == address.id;

    return InkWell(
      onTap: () => setState(() {
        _selectedLocationType = 'address';
        _selectedAddress = address;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryBrown : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppTheme.primaryBrown.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAddressIconColor(
                  address.name,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                address.type.icon,
                color: _getAddressIconColor(address.name),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryBrown
                              : AppTheme.textDark,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.buildingDetails?.isNotEmpty ?? false)
                    Text(
                      address.buildingDetails!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryBrown,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  SavedAddress? _getAddressByTitle(String title) {
    try {
      return _savedAddresses.firstWhere(
        (addr) => addr.name.toLowerCase() == title.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Color _getAddressIconColor(String title) {
    switch (title.toLowerCase()) {
      case 'home':
        return Colors.green;
      case 'work':
      case 'office':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  void _applyLocationSelection() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (_selectedLocationType == 'current') {
      // Use GPS location
      locationProvider.useGpsLocation();
      Navigator.of(context).pop();
    } else if (_selectedLocationType == 'address' && _selectedAddress != null) {
      // Use selected address
      final locationText = _selectedAddress!.fullAddress;
      locationProvider.setManualLocation(locationText, _selectedAddress!.name);
      Navigator.of(context).pop();
    }
  }
}
