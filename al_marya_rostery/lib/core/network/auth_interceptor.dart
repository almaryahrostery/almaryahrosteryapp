import 'package:dio/dio.dart';
import '../utils/app_logger.dart';
import '../services/hybrid_auth_service.dart';

/// HTTP Interceptor for automatic authentication and token refresh
///
/// 🔄 HYBRID AUTH: Uses both Backend JWT and Firebase ID tokens
///
/// Handles:
/// - Automatic auth token injection in requests (JWT preferred, Firebase fallback)
/// - 401 error detection and automatic token refresh
/// - Request retry after successful token refresh
/// - Prevents cascading failures from expired tokens
class AuthInterceptor extends Interceptor {
  final HybridAuthService _authService = HybridAuthService();

  // Track requests being retried to prevent infinite loops
  final Set<String> _retriedRequests = {};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 🔄 HYBRID: Get token (JWT preferred, Firebase fallback)
      final result = await _authService.getAuthToken();
      final token = result['token'] as String?;
      final tokenType = result['tokenType'] as String;

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        AppLogger.info(
          'Auth token (${tokenType.toUpperCase()}) injected for ${options.method} ${options.path}',
          tag: 'AuthInterceptor',
        );
      } else {
        AppLogger.warning(
          'No auth token available for ${options.method} ${options.path}',
          tag: 'AuthInterceptor',
        );
      }

      handler.next(options);
    } catch (e) {
      AppLogger.error(
        'Error in request interceptor',
        tag: 'AuthInterceptor',
        error: e,
      );
      handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if this is a 401 Unauthorized error
    if (err.response?.statusCode == 401) {
      final requestKey = _getRequestKey(err.requestOptions);

      // Check if we've already retried this request
      if (_retriedRequests.contains(requestKey)) {
        AppLogger.error(
          '401 error after retry, token refresh failed',
          tag: 'AuthInterceptor',
        );
        _retriedRequests.remove(requestKey);
        handler.next(err);
        return;
      }

      AppLogger.warning(
        '401 Unauthorized detected, attempting token refresh...',
        tag: 'AuthInterceptor',
      );

      try {
        // Try to refresh token (hybrid method)
        final result = await _authService.getAuthToken(forceRefresh: true);
        final refreshed = result['token'] != null;

        if (refreshed) {
          AppLogger.success(
            'Token refreshed, retrying request',
            tag: 'AuthInterceptor',
          );

          // Mark this request as retried
          _retriedRequests.add(requestKey);

          // Get new token (hybrid method)
          final newToken = await _authService.getToken();

          if (newToken != null) {
            // Clone the original request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            try {
              // Retry the request
              final response = await Dio().request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                  contentType: options.contentType,
                  responseType: options.responseType,
                  receiveTimeout: options.receiveTimeout,
                  sendTimeout: options.sendTimeout,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              );

              // Clean up retry tracking
              _retriedRequests.remove(requestKey);

              AppLogger.success(
                'Request retry succeeded',
                tag: 'AuthInterceptor',
              );

              return handler.resolve(response);
            } catch (retryError) {
              AppLogger.error(
                'Request retry failed',
                tag: 'AuthInterceptor',
                error: retryError,
              );
              _retriedRequests.remove(requestKey);
            }
          }
        } else {
          AppLogger.error(
            'Token refresh failed, user needs to login again',
            tag: 'AuthInterceptor',
          );
        }
      } catch (refreshError) {
        AppLogger.error(
          'Error during token refresh',
          tag: 'AuthInterceptor',
          error: refreshError,
        );
      }
    }

    // Pass error to next handler
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Clean up retry tracking for successful responses
    final requestKey = _getRequestKey(response.requestOptions);
    _retriedRequests.remove(requestKey);

    handler.next(response);
  }

  /// Generate unique key for request to track retries
  String _getRequestKey(RequestOptions options) {
    return '${options.method}:${options.path}';
  }

  /// Clear retry tracking (useful for testing)
  void clearRetryTracking() {
    _retriedRequests.clear();
  }
}
