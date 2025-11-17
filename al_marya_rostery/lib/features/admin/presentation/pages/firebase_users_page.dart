import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_user_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Firebase Users Management Page
/// SINGLE SOURCE OF TRUTH - All users managed in Firebase only
class FirebaseUsersPage extends StatefulWidget {
  const FirebaseUsersPage({Key? key}) : super(key: key);

  @override
  State<FirebaseUsersPage> createState() => _FirebaseUsersPageState();
}

class _FirebaseUsersPageState extends State<FirebaseUsersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<FirebaseUserProvider>(
        context,
        listen: false,
      );
      // HybridAuthService automatically handles token loading
      await provider.fetchFirebaseUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Users Management'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<FirebaseUserProvider>(
                context,
                listen: false,
              ).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<FirebaseUserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.firebaseUsers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Firebase users...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.firebaseUsers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Firebase users found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: AppTheme.primaryBrown),
                    const SizedBox(width: 8),
                    Text(
                      'Total Users: ${provider.totalUsers}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBrown,
                      ),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: ListView.builder(
                  itemCount: provider.firebaseUsers.length,
                  itemBuilder: (context, index) {
                    final user = provider.firebaseUsers[index];
                    return _buildUserCard(context, user, provider);
                  },
                ),
              ),

              // Pagination
              if (provider.totalPages > 1) _buildPagination(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    dynamic user,
    FirebaseUserProvider provider,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.red,
          child: Text(
            (user.displayName?.substring(0, 1) ??
                    user.email?.substring(0, 1) ??
                    '?')
                .toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.displayName ?? user.email ?? 'No name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'No email'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: user.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  user.isActive ? 'Active' : 'Disabled',
                  style: TextStyle(
                    color: user.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  user.emailVerified ? Icons.verified : Icons.warning,
                  size: 16,
                  color: user.emailVerified ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  user.emailVerified ? 'Verified' : 'Not verified',
                  style: TextStyle(
                    color: user.emailVerified ? Colors.blue : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('UID', user.uid),
                if (user.phoneNumber != null)
                  _buildDetailRow('Phone', user.phoneNumber!),
                _buildDetailRow('Role', user.role.toUpperCase()),
                _buildDetailRow(
                  'Created',
                  user.creationTime.isNotEmpty
                      ? dateFormat.format(DateTime.parse(user.creationTime))
                      : 'N/A',
                ),
                _buildDetailRow(
                  'Last Sign In',
                  user.lastSignInTime.isNotEmpty
                      ? dateFormat.format(DateTime.parse(user.lastSignInTime))
                      : 'Never',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        color: user.isActive ? Colors.red : Colors.green,
                      ),
                      label: Text(
                        user.isActive ? 'Disable' : 'Enable',
                        style: TextStyle(
                          color: user.isActive ? Colors.red : Colors.green,
                        ),
                      ),
                      onPressed: () =>
                          _toggleUserStatus(context, user, provider),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => _deleteUser(context, user, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _toggleUserStatus(
    BuildContext context,
    dynamic user,
    FirebaseUserProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Disable User?' : 'Enable User?'),
        content: Text(
          user.isActive
              ? 'This will prevent ${user.email} from logging in.'
              : 'This will allow ${user.email} to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.toggleFirebaseUserStatus(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'User status updated'
                          : 'Failed to update user status',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(
    BuildContext context,
    dynamic user,
    FirebaseUserProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
          'Are you sure you want to permanently delete ${user.email}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteFirebaseUser(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'User deleted' : 'Failed to delete user',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(FirebaseUserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage} of ${provider.totalPages}',
            style: const TextStyle(color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 1
                    ? provider.previousPage
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${provider.currentPage}'),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages
                    ? provider.nextPage
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
