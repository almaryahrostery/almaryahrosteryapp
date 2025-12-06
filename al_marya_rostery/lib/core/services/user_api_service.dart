import 'package:dio/dio.dart';
import '../../data/models/user_model.dart';
import '../utils/app_logger.dart';
import '../constants/app_constants.dart';
import '../network/auth_interceptor.dart';

/// User API Service
/// Handles all user/customer management API calls
class UserApiService {
  final Dio _dio;

  UserApiService() : _dio = Dio() {
    _dio.options.baseUrl = '${AppConstants.baseUrl}/api';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add production-level auth interceptor with auto-retry on 401
    _dio.interceptors.add(AuthInterceptor());

    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          AppLogger.error('API Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // ==================== FETCH OPERATIONS ====================

  /// Fetch all users with pagination, search, and filters
  Future<Map<String, dynamic>> fetchAllUsers({
    int page = 1,
    int limit = 50,
    String? search,
    String? role,
    bool? isActive,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (role != null) {
        queryParams['role'] = role;
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }
      if (sortBy != null) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null) {
        queryParams['sortOrder'] = sortOrder;
      }

      final response = await _dio.get('/users', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final List<dynamic> usersData = response.data['data'] ?? [];
        final users = usersData
            .map((json) => UserModel.fromJson(json))
            .toList();

        return {
          'users': users,
          'pagination': response.data['pagination'] ?? {},
        };
      } else {
        throw Exception('Failed to fetch users');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  /// Fetch single user by ID
  Future<UserModel> fetchUser(String id) async {
    try {
      final response = await _dio.get('/users/$id');

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to fetch user');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  /// Get current authenticated user profile from backend
  Future<UserModel> getMyProfile({required String firebaseToken}) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $firebaseToken'}),
      );

      if (response.data['success'] == true) {
        final profileData = response.data['data'] as Map<String, dynamic>?;
        final normalizedUser = _extractUserJson(profileData);
        return UserModel.fromJson(normalizedUser);
      } else {
        throw Exception('Failed to fetch profile');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  /// Fetch user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio.get('/users/stats');

      if (response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch statistics');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  // ==================== UPDATE OPERATIONS ====================

  /// Update user information
  Future<UserModel> updateUser({
    required String id,
    String? name,
    String? email,
    String? phone,
    List<String>? roles,
    bool? isActive,
    bool? isEmailVerified,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (roles != null) data['roles'] = roles;
      if (isActive != null) data['isActive'] = isActive;
      if (isEmailVerified != null) data['isEmailVerified'] = isEmailVerified;
      if (preferences != null) data['preferences'] = preferences;

      final response = await _dio.put('/users/$id', data: data);

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update user');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Toggle user active status
  Future<bool> toggleActiveStatus(String id, bool isActive) async {
    try {
      final response = await _dio.patch(
        '/users/$id/status',
        data: {'isActive': isActive},
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error toggling status: $e');
    }
  }

  /// Update user roles
  Future<UserModel> updateUserRoles(String id, List<String> roles) async {
    try {
      final response = await _dio.patch(
        '/users/$id/roles',
        data: {'roles': roles},
      );

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update roles');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating roles: $e');
    }
  }

  // ==================== DELETE OPERATION ====================

  /// Delete user (soft delete)
  Future<bool> deleteUser(String id) async {
    try {
      final response = await _dio.delete('/users/$id');
      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // ==================== USER ORDERS ====================

  /// Fetch user's orders
  Future<List<Map<String, dynamic>>> fetchUserOrders(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/orders');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch user orders');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching user orders: $e');
    }
  }

  // ==================== LOYALTY OPERATIONS ====================

  /// Update user loyalty points
  Future<UserModel> updateLoyaltyPoints({
    required String id,
    required int points,
    String? reason,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/$id/loyalty/points',
        data: {'points': points, 'reason': reason},
      );

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update loyalty points');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error updating loyalty points: $e');
    }
  }

  /// Get loyalty history
  Future<List<Map<String, dynamic>>> getLoyaltyHistory(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/loyalty/history');

      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch loyalty history');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching loyalty history: $e');
    }
  }

  // ==================== SEARCH OPERATIONS ====================

  /// Search users by query
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': query},
      );

      if (response.data['success'] == true) {
        final List<dynamic> usersData = response.data['data'] ?? [];
        return usersData.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search users');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // ==================== BULK OPERATIONS ====================

  /// Bulk update user status
  Future<bool> bulkUpdateStatus(List<String> userIds, bool isActive) async {
    try {
      final response = await _dio.post(
        '/users/bulk/status',
        data: {'userIds': userIds, 'isActive': isActive},
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error in bulk update: $e');
    }
  }

  /// Export users to CSV
  Future<String> exportUsers({String? role, bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      if (isActive != null) queryParams['isActive'] = isActive;

      final response = await _dio.get(
        '/users/export',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.plain),
      );

      return response.data as String;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error exporting users: $e');
    }
  }

  /// Update current user's profile with optional avatar
  Future<UserModel> updateMyProfile({
    String? name,
    String? phone,
    String? avatarPath, // Local file path for upload
    required String firebaseToken,
  }) async {
    try {
      AppLogger.network('Updating profile...', tag: 'UserAPI');

      // Create FormData for multipart upload
      final formData = FormData();

      if (name != null && name.isNotEmpty) {
        formData.fields.add(MapEntry('name', name));
      }

      if (phone != null) {
        formData.fields.add(MapEntry('phone', phone));
      }

      // Add avatar file if provided
      if (avatarPath != null && avatarPath.isNotEmpty) {
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(avatarPath, filename: 'profile.jpg'),
          ),
        );
        AppLogger.info('Avatar file added to upload', tag: 'UserAPI');
      }

      final response = await _dio.put(
        '/users/me/profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $firebaseToken',
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      AppLogger.info(
        'Profile update response: ${response.statusCode}',
        tag: 'UserAPI',
      );

      if (response.data['success'] == true) {
        AppLogger.success('Profile updated successfully', tag: 'UserAPI');
        final responseData = response.data['data'] as Map<String, dynamic>?;
        final normalizedUser = _extractUserJson(responseData);
        return UserModel.fromJson(normalizedUser);
      } else {
        final errorMessage =
            response.data['message'] ?? 'Failed to update profile';
        AppLogger.error('Profile update failed: $errorMessage', tag: 'UserAPI');
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Network error updating profile',
        tag: 'UserAPI',
        error: e,
      );

      // Enhanced error handling based on status codes
      if (e.response?.statusCode == 401) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Authentication failed';
        AppLogger.error('Auth error: $errorMessage', tag: 'UserAPI');

        if (errorMessage.contains('Invalid token format')) {
          throw Exception(
            'Invalid authentication token. Please sign out and sign in again.',
          );
        } else if (errorMessage.contains('expired')) {
          throw Exception('Your session has expired. Please sign in again.');
        } else {
          throw Exception('Authentication failed. Please sign in again.');
        }
      } else if (e.response?.statusCode == 413) {
        throw Exception('File too large. Please choose a smaller image.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Invalid request';
        throw Exception(errorMessage);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Upload timeout. Please try again with a smaller image.',
        );
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server response timeout. Please try again.');
      } else {
        throw Exception('Network error: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      AppLogger.error('Error updating profile', tag: 'UserAPI', error: e);
      throw Exception('Error updating profile: $e');
    }
  }

  /// Extracts the user payload regardless of backend nesting format
  Map<String, dynamic> _extractUserJson(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      throw Exception('User data missing from response');
    }

    Map<String, dynamic> userJson;
    if (data['user'] is Map<String, dynamic>) {
      userJson = Map<String, dynamic>.from(
        data['user'] as Map<String, dynamic>,
      );
    } else {
      userJson = Map<String, dynamic>.from(data);
    }

    // Normalize id field for UserModel expectations
    if (!userJson.containsKey('_id') && userJson['id'] != null) {
      userJson['_id'] = userJson['id'];
    }

    userJson.putIfAbsent('preferences', () => {});
    userJson.putIfAbsent('loyaltyProgram', () => {});
    userJson.putIfAbsent('statistics', () => {});

    return userJson;
  }
}
