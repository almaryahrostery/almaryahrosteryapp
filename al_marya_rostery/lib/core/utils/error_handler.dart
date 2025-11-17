import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../network/api_client.dart';
import 'app_logger.dart';

/// Centralized error handling utility for consistent UX
///
/// Provides:
/// - User-friendly error messages
/// - Network error detection and retry logic
/// - Offline detection
/// - Error categorization (temporary vs permanent)
/// - Actionable guidance for users
class ErrorHandler {
  /// Convert any error to user-friendly message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is firebase_auth.FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    } else if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is HttpException) {
      return 'Server error occurred. Please try again later.';
    } else if (error is FormatException) {
      return 'Data format error. Please contact support if this persists.';
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (error is ApiException) {
      return error.message;
    } else if (error is NetworkException) {
      return error.message;
    } else if (error is Exception) {
      final message = error.toString().replaceAll('Exception: ', '');
      return _sanitizeErrorMessage(message);
    }

    return _sanitizeErrorMessage(error.toString());
  }

  /// Handle Dio HTTP errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet and try again.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        // Try to extract backend error message
        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            return _sanitizeErrorMessage(data['message'].toString());
          }
          if (data['error'] != null) {
            return _sanitizeErrorMessage(data['error'].toString());
          }
        }

        // Fallback to status code messages
        switch (statusCode) {
          case 400:
            return 'Invalid request. Please check your information and try again.';
          case 401:
            return 'Your session has expired. Please log in again.';
          case 403:
            return 'You don\'t have permission to perform this action.';
          case 404:
            return 'The requested resource was not found.';
          case 409:
            return 'This action conflicts with existing data. Please refresh and try again.';
          case 422:
            return 'Invalid data provided. Please check your input.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          case 500:
          case 502:
          case 503:
          case 504:
            return 'Server error occurred. Our team has been notified. Please try again later.';
          default:
            return 'Something went wrong. Please try again.';
        }

      case DioExceptionType.connectionError:
        return 'Network connection error. Please check your internet connection.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badCertificate:
        return 'Security error. Please check your connection.';

      case DioExceptionType.unknown:
        return 'Network error occurred. Please try again.';
    }
  }

  /// Handle Firebase Authentication errors
  static String _handleFirebaseAuthError(
    firebase_auth.FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in instead.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account exists with the same email but different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'For security, please log in again to continue.';
      default:
        return 'Authentication error: ${error.message ?? 'Please try again'}';
    }
  }

  /// Sanitize error messages to remove technical jargon
  static String _sanitizeErrorMessage(String message) {
    // Remove common technical prefixes
    message = message
        .replaceAll('Exception: ', '')
        .replaceAll('Error: ', '')
        .replaceAll('DioException: ', '')
        .replaceAll('[firebase_auth/exception] ', '')
        .trim();

    // Make first letter uppercase
    if (message.isNotEmpty) {
      message = message[0].toUpperCase() + message.substring(1);
    }

    // Ensure message ends with period
    if (message.isNotEmpty &&
        !message.endsWith('.') &&
        !message.endsWith('!')) {
      message += '.';
    }

    return message.isEmpty
        ? 'An unexpected error occurred. Please try again.'
        : message;
  }

  /// Determine if error is temporary and can be retried
  static bool isRetryable(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          // Retry on server errors and rate limits
          return statusCode != null && (statusCode >= 500 || statusCode == 429);

        default:
          return false;
      }
    }

    if (error is SocketException || error is HttpException) {
      return true;
    }

    if (error is TimeoutException) {
      return true;
    }

    return false;
  }

  /// Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Show error SnackBar with retry option
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 6),
  }) {
    if (!context.mounted) return;

    final message = getUserFriendlyMessage(error);
    final canRetry = isRetryable(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: (canRetry && onRetry != null)
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );

    // Log for debugging
    AppLogger.error(
      'User-facing error shown',
      tag: 'ErrorHandler',
      error: error,
    );
  }

  /// Show success SnackBar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning SnackBar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required dynamic error,
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;

    final message = getUserFriendlyMessage(error);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Timeout exception
class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Request timed out']);

  @override
  String toString() => message;
}
