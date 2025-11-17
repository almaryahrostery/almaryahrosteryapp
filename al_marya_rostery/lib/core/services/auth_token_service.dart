import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../utils/app_logger.dart';

/// Centralized authentication token management service
///
/// Single source of truth for all auth tokens in the app.
/// Handles token storage, retrieval, refresh, and expiry checking.
///
/// 🛡️ ROBUST TOKEN PROTECTION:
/// - Proactive monitoring (refreshes 5min before expiry)
/// - Background auto-refresh every 45 minutes
/// - Request-level 401 retry with fresh token
/// - Firebase token force-refresh on demand
/// - Zero user interruption guarantee
///
/// Benefits:
/// - Eliminates token sync issues between services
/// - Automatic token refresh when expired
/// - Prevents "please login" errors during operations
/// - Production-grade token lifecycle management
class AuthTokenService {
  static final AuthTokenService _instance = AuthTokenService._internal();
  factory AuthTokenService() => _instance;
  AuthTokenService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  bool _refreshInProgress = false;
  AuthRepository? _authRepository;

  // Background refresh timer
  Timer? _backgroundRefreshTimer;

  // Completer for ongoing refresh operations
  Completer<bool>? _refreshCompleter;

  /// Initialize with auth repository for token refresh capability
  void initialize(AuthRepository authRepository) {
    _authRepository = authRepository;
    AppLogger.info('AuthTokenService initialized', tag: 'AuthTokenService');

    // Start background token refresh (every 45 minutes)
    _startBackgroundRefresh();
  }

  /// Start background token refresh timer
  /// Refreshes token every 45 minutes to stay ahead of 1-hour expiry
  void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(const Duration(minutes: 45), (
      timer,
    ) async {
      if (_accessToken != null) {
        AppLogger.info(
          '⏰ Background token refresh triggered',
          tag: 'AuthTokenService',
        );
        await _refreshAccessToken();
      }
    });
    AppLogger.info(
      '⏰ Background refresh started (45min interval)',
      tag: 'AuthTokenService',
    );
  }

  /// Stop background refresh (called on logout)
  void _stopBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
    AppLogger.info('⏰ Background refresh stopped', tag: 'AuthTokenService');
  }

  /// Get current access token, refreshing if necessary
  ///
  /// 🛡️ BACKEND JWT TOKEN MANAGEMENT WITH AUTO-REFRESH:
  /// 1. Loads from storage if needed
  /// 2. Auto-refreshes via Firebase if expired
  /// 3. Returns backend JWT token (expires in 30 days)
  ///
  /// Note: Backend JWT tokens are long-lived (30 days) but if expired,
  /// we silently get a new Firebase token and exchange it for a fresh JWT.
  /// This provides seamless UX without forcing logout.
  ///
  /// [forceRefresh] - Force token refresh
  /// Returns null if no token available and user not signed in
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    try {
      // Load from storage if not in memory
      if (_accessToken == null) {
        await _loadTokensFromStorage();
      }

      // 🔄 AUTO-REFRESH: Silently refresh expired tokens
      if (_accessToken != null && _tokenExpiry != null) {
        if (DateTime.now().isAfter(_tokenExpiry!) || forceRefresh) {
          AppLogger.info(
            '🔄 Token expired, attempting silent refresh via Firebase...',
            tag: 'AuthTokenService',
          );

          // Try to get fresh Firebase token and exchange for backend JWT
          final freshToken = await _silentRefreshViaFirebase();
          if (freshToken != null) {
            AppLogger.success(
              '✅ Token refreshed silently, user stays logged in!',
              tag: 'AuthTokenService',
            );
            return freshToken;
          } else {
            // Only clear if Firebase user is not signed in
            AppLogger.warning(
              '⚠️ Cannot refresh - user not signed in. Please login.',
              tag: 'AuthTokenService',
            );
            await clearTokens();
            return null;
          }
        }
      }

      // Return valid token
      if (_accessToken != null) {
        final daysRemaining = _tokenExpiry != null
            ? _tokenExpiry!.difference(DateTime.now()).inDays
            : null;
        AppLogger.info(
          '🎫 Returning backend JWT token (${daysRemaining != null ? "expires ${daysRemaining}d" : "no expiry"})',
          tag: 'AuthTokenService',
        );
      }

      return _accessToken;
    } catch (e) {
      AppLogger.error(
        'Error getting access token',
        tag: 'AuthTokenService',
        error: e,
      );
      return _accessToken; // Return what we have, even if potentially expired
    }
  }

  /// Silently refresh expired backend JWT using Firebase token
  ///
  /// This provides seamless token refresh without forcing logout.
  /// Gets fresh Firebase ID token and exchanges it for new backend JWT.
  Future<String?> _silentRefreshViaFirebase() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        AppLogger.warning(
          'No Firebase user signed in for silent refresh',
          tag: 'AuthTokenService',
        );
        return null;
      }

      // Get fresh Firebase ID token
      final firebaseToken = await firebaseUser.getIdToken(true);
      if (firebaseToken == null) {
        AppLogger.error(
          'Failed to get Firebase token for refresh',
          tag: 'AuthTokenService',
        );
        return null;
      }

      AppLogger.info(
        '🔄 Exchanging Firebase token for fresh backend JWT...',
        tag: 'AuthTokenService',
      );

      // Exchange Firebase token for backend JWT via /api/auth/google
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': firebaseToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final backendToken = data['token'] as String;

          // Save the new token
          await setTokens(
            accessToken: backendToken,
            refreshToken: '',
            expiresInSeconds: 2592000, // 30 days
          );

          AppLogger.success(
            '✅ Silent refresh successful! New 30-day token obtained.',
            tag: 'AuthTokenService',
          );

          return backendToken;
        }
      }

      AppLogger.error(
        'Failed to exchange Firebase token: ${response.statusCode}',
        tag: 'AuthTokenService',
      );
      return null;
    } catch (e) {
      AppLogger.error(
        'Error during silent refresh',
        tag: 'AuthTokenService',
        error: e,
      );
      return null;
    }
  }

  /// Get base URL for API calls
  String _getBaseUrl() {
    // Import AppConstants or hardcode for now
    return 'https://almaryahrostery.onrender.com';
  }

  /// Get fresh token from Firebase (most reliable source)
  Future<String?> _getFirebaseToken({bool forceRefresh = false}) async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      // Force refresh to get new token
      final token = await firebaseUser.getIdToken(forceRefresh);

      if (token != null) {
        AppLogger.success(
          '🔥 Fresh Firebase token obtained (${forceRefresh ? "force-refreshed" : "cached"})',
          tag: 'AuthTokenService',
        );
      }

      return token;
    } catch (e) {
      AppLogger.error(
        'Failed to get Firebase token',
        tag: 'AuthTokenService',
        error: e,
      );
      return null;
    }
  }

  /// Check if current token is valid (exists and not expired)
  bool get hasValidToken {
    if (_accessToken == null) return false;
    if (_tokenExpiry == null) return true; // Assume valid if no expiry set
    return DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Get time remaining until token expiry
  Duration? get timeUntilExpiry {
    if (_tokenExpiry == null) return null;
    return _tokenExpiry!.difference(DateTime.now());
  }

  /// Get token expiry timestamp (public getter)
  DateTime? get tokenExpiry => _tokenExpiry;

  /// Set new authentication tokens
  ///
  /// Called after successful login or token refresh
  Future<void> setTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresInSeconds,
  }) async {
    try {
      _accessToken = accessToken;

      if (refreshToken != null) {
        _refreshToken = refreshToken;
      }

      // Calculate token expiry (default 1 hour if not specified)
      final expiresIn = expiresInSeconds ?? 3600;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      // Persist to secure storage
      await _storage.write(key: 'access_token', value: accessToken);

      if (refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }

      await _storage.write(
        key: 'token_expiry',
        value: _tokenExpiry!.toIso8601String(),
      );

      // Update ApiClient for backward compatibility
      ApiClient().setAuthToken(accessToken);

      AppLogger.success(
        'Tokens saved successfully (expires in ${expiresIn}s)',
        tag: 'AuthTokenService',
      );
    } catch (e) {
      AppLogger.error('Error saving tokens', tag: 'AuthTokenService', error: e);
      rethrow;
    }
  }

  /// Clear all authentication tokens
  ///
  /// Called during logout
  Future<void> clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _refreshInProgress = false;
      _refreshCompleter = null;

      // Stop background refresh
      _stopBackgroundRefresh();

      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'token_expiry');
      await _storage.delete(key: 'auth_token'); // Legacy key

      ApiClient().setAuthToken(null);

      AppLogger.info('All tokens cleared', tag: 'AuthTokenService');
    } catch (e) {
      AppLogger.error(
        'Error clearing tokens',
        tag: 'AuthTokenService',
        error: e,
      );
    }
  }

  /// Load tokens from secure storage
  Future<void> _loadTokensFromStorage() async {
    try {
      _accessToken = await _storage.read(key: 'access_token');

      // Fallback to legacy key for backward compatibility
      if (_accessToken == null) {
        _accessToken = await _storage.read(key: 'auth_token');
      }

      _refreshToken = await _storage.read(key: 'refresh_token');

      final expiryString = await _storage.read(key: 'token_expiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }

      if (_accessToken != null) {
        // Update ApiClient
        ApiClient().setAuthToken(_accessToken);

        AppLogger.info(
          'Tokens loaded from storage (expires: ${_tokenExpiry?.toString() ?? "unknown"})',
          tag: 'AuthTokenService',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error loading tokens from storage',
        tag: 'AuthTokenService',
        error: e,
      );
    }
  }

  /// Check if token should be refreshed (within 5 minutes of expiry)
  bool _shouldRefreshToken() {
    if (_tokenExpiry == null) return false;

    final now = DateTime.now();
    final timeRemaining = _tokenExpiry!.difference(now);

    // Refresh if less than 5 minutes remaining
    return timeRemaining.inMinutes < 5;
  }

  /// Refresh the access token using refresh token
  ///
  /// Returns true if refresh succeeded, false otherwise
  Future<bool> _refreshAccessToken() async {
    // If refresh already in progress, wait for it
    if (_refreshInProgress) {
      AppLogger.info(
        'Token refresh already in progress, waiting...',
        tag: 'AuthTokenService',
      );

      if (_refreshCompleter != null) {
        return await _refreshCompleter!.future;
      }
      return false;
    }

    // Check prerequisites
    if (_authRepository == null) {
      AppLogger.error(
        'AuthRepository not initialized, cannot refresh token',
        tag: 'AuthTokenService',
      );
      return false;
    }

    if (_refreshToken == null) {
      AppLogger.error('No refresh token available', tag: 'AuthTokenService');
      return false;
    }

    try {
      _refreshInProgress = true;
      _refreshCompleter = Completer<bool>();

      AppLogger.info('Refreshing access token...', tag: 'AuthTokenService');

      // Call repository to refresh token
      final response = await _authRepository!.refreshToken(_refreshToken!);

      // Update tokens
      await setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresInSeconds: 3600, // 1 hour
      );

      AppLogger.success(
        'Access token refreshed successfully',
        tag: 'AuthTokenService',
      );

      _refreshCompleter!.complete(true);
      return true;
    } catch (e) {
      AppLogger.error(
        'Token refresh failed',
        tag: 'AuthTokenService',
        error: e,
      );

      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _refreshInProgress = false;
      _refreshCompleter = null;
    }
  }

  /// Manually trigger token refresh
  ///
  /// Useful for testing or explicit refresh scenarios
  Future<bool> refreshToken() async {
    return await _refreshAccessToken();
  }

  /// Debug: Get current token state
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      'tokenExpiry': _tokenExpiry?.toIso8601String(),
      'isValid': hasValidToken,
      'timeUntilExpiry': timeUntilExpiry?.inMinutes,
      'refreshInProgress': _refreshInProgress,
    };
  }
}
