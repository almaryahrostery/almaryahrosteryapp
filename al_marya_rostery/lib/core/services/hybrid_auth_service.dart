import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/app_logger.dart';
import 'auth_token_service.dart';

/// 🔄 Hybrid Authentication Service
///
/// Provides seamless token retrieval with automatic fallback:
/// 1. Tries to get Backend JWT token (preferred, 30-day expiry)
/// 2. Falls back to Firebase ID token if JWT unavailable
/// 3. Returns null only if both methods fail
///
/// This ensures maximum reliability across the entire app.
class HybridAuthService {
  static final HybridAuthService _instance = HybridAuthService._internal();
  factory HybridAuthService() => _instance;
  HybridAuthService._internal();

  final AuthTokenService _tokenService = AuthTokenService();

  /// Get authentication token with automatic fallback
  ///
  /// Returns:
  /// - Backend JWT token if available (preferred)
  /// - Firebase ID token if JWT not available (fallback)
  /// - null if user not authenticated
  ///
  /// Also returns which token type was used for logging/debugging.
  Future<Map<String, dynamic>> getAuthToken({bool forceRefresh = false}) async {
    String? token;
    String tokenType = 'none';

    // STEP 1: Try to get backend JWT token (preferred)
    try {
      AppLogger.debug('🔐 Attempting to get backend JWT token...');
      token = await _tokenService.getAccessToken(forceRefresh: forceRefresh);

      if (token != null) {
        tokenType = 'jwt';
        AppLogger.success('✅ Backend JWT token obtained');
        return {'token': token, 'tokenType': tokenType};
      }
    } catch (e) {
      AppLogger.warning('⚠️ Could not get backend JWT: $e');
    }

    // STEP 2: Fallback to Firebase ID token
    try {
      AppLogger.info('🔄 Falling back to Firebase ID token...');
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        token = await firebaseUser.getIdToken(forceRefresh);
        if (token != null) {
          tokenType = 'firebase';
          AppLogger.success('✅ Firebase ID token obtained');
          return {'token': token, 'tokenType': tokenType};
        }
      }
    } catch (e) {
      AppLogger.error('❌ Firebase token error: $e');
    }

    // STEP 3: No token available
    if (token == null) {
      AppLogger.warning('⚠️ No authentication token available');
    }

    return {'token': token, 'tokenType': tokenType};
  }

  /// Get just the token string (simplified API)
  Future<String?> getToken({bool forceRefresh = false}) async {
    final result = await getAuthToken(forceRefresh: forceRefresh);
    return result['token'] as String?;
  }

  /// Get auth headers ready for HTTP requests
  Future<Map<String, String>> getAuthHeaders({
    bool forceRefresh = false,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };

    final result = await getAuthToken(forceRefresh: forceRefresh);
    final token = result['token'] as String?;
    final tokenType = result['tokenType'] as String;

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      AppLogger.debug('🔐 Using ${tokenType.toUpperCase()} token for request');
    }

    return headers;
  }

  /// Check if user is authenticated (has any valid token)
  Future<bool> isAuthenticated() async {
    final result = await getAuthToken();
    return result['token'] != null;
  }
}
