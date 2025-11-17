import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/address_provider.dart';
import '../models/user_address.dart';
import '../widgets/address_card.dart';
import 'add_address_screen.dart';
import '../../../core/theme/app_theme.dart';

class EnhancedAddressesPage extends StatefulWidget {
  const EnhancedAddressesPage({super.key});

  @override
  State<EnhancedAddressesPage> createState() => _EnhancedAddressesPageState();
}

class _EnhancedAddressesPageState extends State<EnhancedAddressesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAddresses();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      // Reload addresses with distance calculation
      _loadAddresses();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadAddresses() async {
    await context.read<AddressProvider>().loadAddressesFromBackend(
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Addresses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Addresses'),
            Tab(text: 'Locker/Pickup Points'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for your building or street',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                // Trigger rebuild for search filtering
                setState(() {});
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAddressesTab(), _buildLockersTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          );
          if (result == true && mounted) {
            _loadAddresses();
          }
        },
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add New Address'),
      ),
    );
  }

  Widget _buildAddressesTab() {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.addresses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBrown),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAddresses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBrown,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Filter addresses based on search
        final filteredAddresses = _filterAddresses(provider.addresses);

        if (filteredAddresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No addresses yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first address to get started',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadAddresses,
          color: AppTheme.primaryBrown,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filteredAddresses.length,
            itemBuilder: (context, index) {
              final address = filteredAddresses[index];
              return AddressCard(
                address: address,
                showDistance: _currentPosition != null,
                onEdit: () => _editAddress(address),
                onDelete: () => _deleteAddress(address),
                onSetDefault: () => _setDefaultAddress(address),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLockersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Locker/Pickup Points',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Coming soon!', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  List<UserAddress> _filterAddresses(List<UserAddress> addresses) {
    if (_searchController.text.isEmpty) {
      return addresses;
    }

    final query = _searchController.text.toLowerCase();
    return addresses.where((address) {
      return address.formattedAddress.toLowerCase().contains(query) ||
          address.label.toLowerCase().contains(query) ||
          address.building.toLowerCase().contains(query) ||
          address.street.toLowerCase().contains(query) ||
          address.area.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _editAddress(UserAddress address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddAddressScreen(existingAddress: address, isEditMode: true),
      ),
    );
    if (result == true && mounted) {
      _loadAddresses();
    }
  }

  Future<void> _deleteAddress(UserAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.label}"?'),
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

    if (confirmed == true && mounted) {
      final success = await context
          .read<AddressProvider>()
          .deleteAddressFromBackend(address.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Address deleted' : 'Failed to delete'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadAddresses();
      }
    }
  }

  Future<void> _setDefaultAddress(UserAddress address) async {
    final success = await context
        .read<AddressProvider>()
        .setDefaultAddressInBackend(address.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Default address updated' : 'Failed to update',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _loadAddresses();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
