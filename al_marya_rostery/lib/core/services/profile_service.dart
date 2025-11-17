import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'hybrid_auth_service.dart';

/// Profile service for managing user profile data and updates
class ProfileService {
  final Dio _dio = Dio();
  final HybridAuthService _authService = HybridAuthService();

  ProfileService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.get(
        '/api/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['user'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load profile');
      }
    } on DioException catch (e) {
      debugPrint('Profile fetch error: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? dateOfBirth,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
      if (preferences != null) updateData['preferences'] = preferences;

      final response = await _dio.put(
        '/api/auth/profile',
        data: updateData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['user'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      debugPrint('Profile update error: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        '/api/auth/upload-avatar',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['avatarUrl'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload image');
      }
    } on DioException catch (e) {
      debugPrint('Image upload error: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.put(
        '/api/auth/preferences',
        data: {'preferences': preferences},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200 || !response.data['success']) {
        throw Exception(
          response.data['message'] ?? 'Failed to update preferences',
        );
      }
    } on DioException catch (e) {
      debugPrint('Preferences update error: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Failed to update preferences: $e');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.put(
        '/api/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200 || !response.data['success']) {
        throw Exception(
          response.data['message'] ?? 'Failed to change password',
        );
      }
    } on DioException catch (e) {
      debugPrint('Password change error: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.delete(
        '/api/auth/account',
        data: {'password': password},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200 || !response.data['success']) {
        throw Exception(response.data['message'] ?? 'Failed to delete account');
      }
    } on DioException catch (e) {
      debugPrint('Account deletion error: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Handle Dio errors and convert them to user-friendly messages
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'];

        if (statusCode == 401) {
          return Exception('Session expired. Please login again.');
        } else if (statusCode == 403) {
          return Exception('Access denied. You do not have permission.');
        } else if (statusCode == 404) {
          return Exception('Profile not found.');
        } else if (statusCode == 422) {
          return Exception(message ?? 'Invalid data provided.');
        } else {
          return Exception(message ?? 'Server error. Please try again later.');
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.unknown:
        return Exception(
          'Network error. Please check your internet connection.',
        );
      default:
        return Exception('An unexpected error occurred.');
    }
  }
}
