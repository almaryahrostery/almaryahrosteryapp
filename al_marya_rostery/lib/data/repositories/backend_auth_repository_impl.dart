import 'package:qahwat_al_emarat/domain/repositories/auth_repository.dart';
import 'package:qahwat_al_emarat/domain/models/auth_models.dart';
import 'package:qahwat_al_emarat/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Backend API implementation of AuthRepository
/// Connects to Node.js backend at almaryarostary.onrender.com
class BackendAuthRepositoryImpl implements AuthRepository {
  final http.Client _httpClient;
  final String _baseUrl = AppConstants.baseUrl;

  BackendAuthRepositoryImpl({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  @override
  Future<bool> isLoggedIn() async {
    // Check if we have a valid token stored
    // This will be implemented with secure storage
    return false;
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Get auth token from storage
      final token = await _tokenService.getAccessToken();
      if (token == null) return null;

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];

        return User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          avatar: userData['avatar'],
          isEmailVerified: userData['isEmailVerified'] ?? false,
          roles: (userData['roles'] as List?)?.cast<String>() ?? ['user'],
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];
        final token = data['data']['token'];
        final refreshToken = data['data']['refreshToken'];

        return AuthResponse(
          user: User(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
            avatar: userData['avatar'],
            isEmailVerified: userData['isEmailVerified'] ?? false,
            roles: (userData['roles'] as List?)?.cast<String>() ?? ['user'],
          ),
          accessToken: token,
          refreshToken: refreshToken ?? '',
          expiresIn: data['data']['expiresIn'] ?? 3600,
          tokenType: 'Bearer',
        );
      } else {
        throw AuthException(
          data['message'] ?? 'Login failed',
          data['error']?['code'],
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final userData = data['data']['user'];
        final token = data['data']['token'];
        final refreshToken = data['data']['refreshToken'];

        return AuthResponse(
          user: User(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            phone: userData['phone'],
            avatar: userData['avatar'],
            isEmailVerified: userData['isEmailVerified'] ?? false,
            roles: (userData['roles'] as List?)?.cast<String>() ?? ['user'],
          ),
          accessToken: token,
          refreshToken: refreshToken ?? '',
          expiresIn: data['data']['expiresIn'] ?? 3600,
          tokenType: 'Bearer',
        );
      } else {
        throw AuthException(
          data['message'] ?? 'Registration failed',
          data['error']?['code'],
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponse> signInWithGoogle() async {
    // Google Sign-In will still use Firebase
    // Then send token to backend for verification
    throw UnimplementedError('Use Firebase repository for Google Sign-In');
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw AuthException(data['message'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(
    String token,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw AuthException(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    // Clear stored tokens
    // Backend doesn't need to be notified for stateless JWT auth
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    throw UnimplementedError('Change password not yet implemented');
  }

  @override
  Future<void> sendEmailVerification() async {
    throw UnimplementedError('Email verification not yet implemented');
  }

  @override
  Future<void> verifyEmail(String verificationToken) async {
    throw UnimplementedError('Email verification not yet implemented');
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    throw UnimplementedError('Token refresh not yet implemented');
  }

  @override
  Future<AuthResponse> updateProfile(User updatedUser) async {
    throw UnimplementedError('Profile update not yet implemented');
  }

  @override
  Future<AuthResponse> updateProfileWithFile(
    String? name,
    String? phone,
    dynamic avatarFile,
  ) async {
    throw UnimplementedError('Profile update with file not yet implemented');
  }
}
