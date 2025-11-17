import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/admin_user_model.dart';
import '../../data/models/user_statistics_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/hybrid_auth_service.dart';

class AdminUserProvider with ChangeNotifier {
  List<AdminUser> _users = [];
  UserStatistics? _userStats;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  String _searchQuery = '';
  String _selectedRole = '';
  String _selectedStatus = '';

  final HybridAuthService _authService = HybridAuthService();

  // Getters
  List<AdminUser> get users => _users;
  UserStatistics? get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalUsers => _totalUsers;
  String get searchQuery => _searchQuery;
  String get selectedRole => _selectedRole;
  String get selectedStatus => _selectedStatus;

  // Base URL - Uses AppConstants for environment configuration
  String get baseUrl => '${AppConstants.baseUrl}/api/admin';

  /// Get headers with auth token (hybrid: JWT or Firebase)
  Future<Map<String, String>> _getHeaders() async {
    return await _authService.getAuthHeaders();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Fetch users with pagination and filters
  Future<void> fetchUsers({
    int page = 1,
    int limit = 10,
    String? search,
    String? role,
    String? status,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        _searchQuery = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
        _selectedRole = role;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
        _selectedStatus = status;
      }

      final uri = Uri.parse(
        '$baseUrl/users',
      ).replace(queryParameters: queryParams);

      debugPrint('🔍 Fetching users from: $uri');
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _users = (data['users'] as List)
            .map((userJson) => AdminUser.fromJson(userJson))
            .toList();
        _currentPage = data['currentPage'] ?? 1;
        _totalPages = data['totalPages'] ?? 1;
        _totalUsers = data['totalUsers'] ?? 0;
      } else {
        _setError('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error fetching users: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch user statistics
  Future<void> fetchUserStatistics() async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('🔍 Fetching user statistics from: $baseUrl/users/stats');
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userStats = UserStatistics.fromJson(data);
      } else {
        _setError('Failed to fetch user statistics: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error fetching user statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update user
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _setError(null);

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final updatedUserData = json.decode(response.body);
        final updatedUser = AdminUser.fromJson(updatedUserData['user']);

        // Update the user in the local list
        final index = _users.indexWhere((user) => user.id == userId);
        if (index != -1) {
          _users[index] = updatedUser;
          notifyListeners();
        }

        return true;
      } else {
        _setError('Failed to update user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _setError('Error updating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Remove the user from the local list
        _users.removeWhere((user) => user.id == userId);
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Bulk update users
  Future<bool> bulkUpdateUsers(
    List<String> userIds,
    Map<String, dynamic> updates,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/bulk'),
        headers: headers,
        body: json.encode({'userIds': userIds, 'updates': updates}),
      );

      if (response.statusCode == 200) {
        // Refresh the user list
        await fetchUsers(page: _currentPage);
        return true;
      } else {
        _setError('Failed to bulk update users: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _setError('Error bulk updating users: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    return await updateUser(userId, {'isActive': isActive});
  }

  // Update user role
  Future<bool> updateUserRole(String userId, List<String> roles) async {
    return await updateUser(userId, {'roles': roles});
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedRole = '';
    _selectedStatus = '';
    notifyListeners();
  }

  // Search users
  void searchUsers(String query) {
    _currentPage = 1;
    fetchUsers(search: query, role: _selectedRole, status: _selectedStatus);
  }

  // Filter by role
  void filterByRole(String role) {
    _currentPage = 1;
    fetchUsers(search: _searchQuery, role: role, status: _selectedStatus);
  }

  // Filter by status
  void filterByStatus(String status) {
    _currentPage = 1;
    fetchUsers(search: _searchQuery, role: _selectedRole, status: status);
  }

  // Go to next page
  void nextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      fetchUsers(
        page: _currentPage,
        search: _searchQuery,
        role: _selectedRole,
        status: _selectedStatus,
      );
    }
  }

  // Go to previous page
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      fetchUsers(
        page: _currentPage,
        search: _searchQuery,
        role: _selectedRole,
        status: _selectedStatus,
      );
    }
  }

  // Go to specific page
  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      fetchUsers(
        page: _currentPage,
        search: _searchQuery,
        role: _selectedRole,
        status: _selectedStatus,
      );
    }
  }
}
