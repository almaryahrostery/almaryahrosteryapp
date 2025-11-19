import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../core/widgets/skeleton_loaders.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../services/address_service.dart';
import '../models/saved_address.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfilePageWrapper();
  }
}

// Add a wrapper widget to handle provider access safely
class _ProfilePageWrapper extends StatelessWidget {
  const _ProfilePageWrapper();

  @override
  Widget build(BuildContext context) {
    try {
      // Try to access the provider to validate it exists
      Provider.of<AuthProvider>(context, listen: false);
      return const _ProfilePageContent();
    } catch (e) {
      debugPrint('ProfilePage: AuthProvider not found: $e');
      // Return error page if provider is not available
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryBrown,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Profile Unavailable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Authentication service is not available.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _ProfilePageContent extends StatefulWidget {
  const _ProfilePageContent();

  @override
  State<_ProfilePageContent> createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<_ProfilePageContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  SavedAddress? _selectedAddress;
  double _profileCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';

        // Load saved addresses
        try {
          final addressService = AddressService();
          _selectedAddress = await addressService.getDefaultAddress();

          if (_selectedAddress != null) {
            _addressController.text = _selectedAddress!.fullAddress;
            // Extract city from address (simple approach)
            final addressParts = _selectedAddress!.fullAddress.split(',');
            _cityController.text = addressParts.length > 1
                ? addressParts.last.trim()
                : '';
          }
        } catch (e) {
          debugPrint('Error loading addresses: $e');
        }

        // Load notification preferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _emailNotifications = prefs.getBool('email_notifications') ?? true;
          _pushNotifications = prefs.getBool('push_notifications') ?? true;
        });

        // Calculate profile completion
        _calculateProfileCompletion();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Handle the case where AuthProvider is not available
      _nameController.text = '';
      _emailController.text = '';
      _phoneController.text = '';
      _addressController.text = '';
      _cityController.text = '';
    }
  }

  void _calculateProfileCompletion() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      setState(() => _profileCompletion = 0.0);
      return;
    }

    int completed = 0;
    int total = 7;

    if (user.name.isNotEmpty) completed++;
    if (user.email.isNotEmpty) completed++;
    if (user.phone?.isNotEmpty ?? false) completed++;
    if (user.avatar?.isNotEmpty ?? false) completed++;
    if (_addressController.text.isNotEmpty) completed++;
    if (_cityController.text.isNotEmpty) completed++;
    // Email verification counted as bonus
    completed++; // Base completion

    setState(() {
      _profileCompletion = (completed / total) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryBrown, // primaryBrown
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5), // backgroundLight
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Handle loading state
          if (!authProvider.isInitialized) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ProfileSectionSkeleton(),
                  const SizedBox(height: 16),
                  const ProfileSectionSkeleton(),
                  const SizedBox(height: 16),
                  const ProfileSectionSkeleton(),
                ],
              ),
            );
          }

          if (!authProvider.isAuthenticated) {
            return _buildGuestView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadUserData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppTheme.primaryBrown,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(authProvider.user!),
                    const SizedBox(height: 24),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 16),
                    _buildContactInfoCard(),
                    const SizedBox(height: 16),
                    _buildPreferencesCard(),
                    const SizedBox(height: 16),
                    _buildAccountActionsCard(authProvider),
                    const SizedBox(height: 24),
                    if (_isEditing) _buildActionButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 80,
              color: Color(0xFF8C8C8C),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign in to view your profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5D5D5D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an account or sign in to manage your profile, orders, and preferences.',
              style: TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Replace entire stack with login page for clean navigation
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryBrown.withValues(alpha: 0.1),
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (user.avatar?.isNotEmpty == true
                          ? CachedNetworkImageProvider(user.avatar!)
                          : null),
                child: _selectedImage == null && (user.avatar?.isEmpty ?? true)
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryBrown,
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA000), // accentAmber
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            (user.name.isNotEmpty ? user.name : null) ??
                user.email.split('@').first,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.email ?? '',
                style: const TextStyle(fontSize: 14, color: Color(0xFF8C8C8C)),
              ),
              if (user.isEmailVerified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 16,
                    color: AppTheme.primaryBrown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Profile ${_profileCompletion.toStringAsFixed(0)}% Complete',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _profileCompletion / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _profileCompletion >= 80
                        ? Colors.green
                        : _profileCompletion >= 50
                        ? AppTheme.accentAmber
                        : Colors.orange,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          if (user.roles?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.roles!.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBrown,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              enabled: _isEditing,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              enabled: false, // Email should not be editable
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              validator: (value) {
                if (value?.isEmpty ?? true) return null;

                // UAE phone number validation
                // Formats: +971501234567, 971501234567, 0501234567, 501234567
                final cleaned = value!.replaceAll(RegExp(r'\s+'), '');

                if (cleaned.startsWith('+971')) {
                  if (!RegExp(
                    r'^\+971(50|52|54|55|56|58|2|3|4|6|7|9)\d{7}$',
                  ).hasMatch(cleaned)) {
                    return 'Invalid UAE number (e.g., +971501234567)';
                  }
                } else if (cleaned.startsWith('971')) {
                  if (!RegExp(
                    r'^971(50|52|54|55|56|58|2|3|4|6|7|9)\d{7}$',
                  ).hasMatch(cleaned)) {
                    return 'Invalid UAE number (e.g., 971501234567)';
                  }
                } else if (cleaned.startsWith('0')) {
                  if (!RegExp(
                    r'^0(50|52|54|55|56|58|2|3|4|6|7|9)\d{7}$',
                  ).hasMatch(cleaned)) {
                    return 'Invalid UAE number (e.g., 0501234567)';
                  }
                } else if (!RegExp(
                  r'^(50|52|54|55|56|58)\d{7}$',
                ).hasMatch(cleaned)) {
                  return 'Invalid UAE number (e.g., 501234567)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Address Selection
            InkWell(
              onTap: _isEditing ? _showAddressManagement : null,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: _isEditing
                        ? AppTheme.primaryBrown
                        : const Color(0xFF8C8C8C),
                  ),
                  suffixIcon: _isEditing
                      ? const Icon(Icons.edit, size: 20)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  filled: true,
                  fillColor: _isEditing
                      ? Colors.white
                      : const Color(0xFFF9F9F9),
                ),
                child: Text(
                  _addressController.text.isEmpty
                      ? 'Tap to select address'
                      : _addressController.text,
                  style: TextStyle(
                    color: _addressController.text.isEmpty
                        ? const Color(0xFF8C8C8C)
                        : const Color(0xFF2E2E2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cityController,
              label: 'City',
              icon: Icons.location_city,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 16),
            _buildNotificationPreference(),
            const Divider(height: 24),
            _buildPreferenceItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            _buildPreferenceItem(
              icon: Icons.dark_mode,
              title: 'Theme',
              subtitle: 'Light mode',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsCard(AuthProvider authProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () => Navigator.pushNamed(context, '/change-password'),
            ),
            _buildActionItem(
              icon: Icons.security,
              title: 'Privacy Settings',
              subtitle: 'Manage your privacy preferences',
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            _buildActionItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help with your account',
              onTap: () => Navigator.pushNamed(context, '/help-support'),
            ),
            _buildActionItem(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              textColor: Colors.red,
              onTap: () => _showSignOutDialog(authProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? AppTheme.primaryBrown : const Color(0xFF8C8C8C),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBrown),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF9F9F9),
      ),
    );
  }

  Future<void> _showAddressManagement() async {
    final selected = await Navigator.pushNamed(context, '/address-management');

    if (selected != null && selected is SavedAddress) {
      setState(() {
        _selectedAddress = selected;
        _addressController.text = selected.fullAddress;
        final addressParts = selected.fullAddress.split(',');
        _cityController.text = addressParts.length > 1
            ? addressParts.last.trim()
            : '';
      });
      _calculateProfileCompletion();
    }
  }

  Widget _buildNotificationPreference() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.email,
              color: AppTheme.primaryBrown,
              size: 20,
            ),
          ),
          title: const Text(
            'Email Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E2E2E),
            ),
          ),
          subtitle: const Text(
            'Receive order updates via email',
            style: TextStyle(fontSize: 12, color: Color(0xFF8C8C8C)),
          ),
          value: _emailNotifications,
          activeColor: AppTheme.primaryBrown,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications,
              color: AppTheme.primaryBrown,
              size: 20,
            ),
          ),
          title: const Text(
            'Push Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E2E2E),
            ),
          ),
          subtitle: const Text(
            'Receive push notifications on your device',
            style: TextStyle(fontSize: 12, color: Color(0xFF8C8C8C)),
          ),
          value: _pushNotifications,
          activeColor: AppTheme.primaryBrown,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBrown.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryBrown, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF2E2E2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8C8C8C)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C8C8C)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppTheme.primaryBrown).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: textColor ?? AppTheme.primaryBrown, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF2E2E2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8C8C8C)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8C8C8C)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _selectedImage = null;
                _loadUserData(); // Reset form data
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBrown,
              side: const BorderSide(color: AppTheme.primaryBrown),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      // Show option to pick from gallery or camera
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.primaryBrown,
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryBrown,
                ),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        // Validate file size (max 5MB)
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Image too large. Please select an image under 5MB.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image selected. Save changes to update your profile picture.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String message = 'Failed to pick image';
        if (e.code == 'camera_access_denied') {
          message = 'Camera permission denied. Please enable in settings.';
        } else if (e.code == 'photo_access_denied') {
          message =
              'Photo library permission denied. Please enable in settings.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _pickImage,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _pickImage,
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Normalize phone number
      String? phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        // Remove spaces and ensure UAE format
        phone = phone.replaceAll(RegExp(r'\s+'), '');
        if (!phone.startsWith('+')) {
          if (phone.startsWith('971')) {
            phone = '+$phone';
          } else if (phone.startsWith('0')) {
            phone = '+971${phone.substring(1)}';
          } else {
            phone = '+971$phone';
          }
        }
      }

      // Call the actual profile update API
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: phone.isNotEmpty ? phone : null,
        avatarFile: _selectedImage,
      );

      // Save notification preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);

      // Recalculate profile completion
      _calculateProfileCompletion();

      setState(() {
        _isEditing = false;
        _isLoading = false;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Profile updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on SocketException {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No internet connection. Please check your network.',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.message ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        if (e.toString().contains('timeout')) {
          errorMessage = 'Request timeout. Please try again.';
        } else if (e.toString().contains('unauthorized')) {
          errorMessage = 'Session expired. Please log in again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveProfile,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showSignOutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Get navigator before async operations
              final navigator = Navigator.of(context, rootNavigator: true);

              navigator.pop(); // Close dialog

              // Wait a frame for UI to settle
              await Future.delayed(const Duration(milliseconds: 100));

              // Perform logout
              await authProvider.logout();

              // Wait for logout to complete fully
              await Future.delayed(const Duration(milliseconds: 100));

              // Navigate to login
              if (context.mounted) {
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
