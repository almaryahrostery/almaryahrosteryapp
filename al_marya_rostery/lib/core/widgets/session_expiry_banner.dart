import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_token_service.dart';
import '../utils/app_logger.dart';

/// Session Expiry Warning Banner
///
/// Shows a countdown warning when token is about to expire.
/// Provides option to extend session with one tap.
/// Prevents abrupt logout during critical operations.
class SessionExpiryBanner extends StatefulWidget {
  final Widget child;

  const SessionExpiryBanner({super.key, required this.child});

  @override
  State<SessionExpiryBanner> createState() => _SessionExpiryBannerState();
}

class _SessionExpiryBannerState extends State<SessionExpiryBanner> {
  final AuthTokenService _tokenService = AuthTokenService();
  Timer? _checkTimer;
  bool _showWarning = false;
  Duration _remainingTime = Duration.zero;
  bool _isRefreshing = false;

  // Show warning when less than 5 minutes remaining
  static const _warningThreshold = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkTokenExpiry();
    });

    // Initial check
    _checkTokenExpiry();
  }

  Future<void> _checkTokenExpiry() async {
    try {
      final token = await _tokenService.getAccessToken();

      if (token == null) {
        // Not logged in, hide warning
        if (mounted && _showWarning) {
          setState(() {
            _showWarning = false;
          });
        }
        return;
      }

      final expiry = _tokenService.tokenExpiry;
      if (expiry == null) return;

      final now = DateTime.now();
      final remaining = expiry.difference(now);

      // Show warning if expiring soon
      if (remaining.isNegative) {
        // Already expired, will be handled by silent refresh
        if (mounted && _showWarning) {
          setState(() {
            _showWarning = false;
          });
        }
      } else if (remaining < _warningThreshold) {
        if (mounted) {
          setState(() {
            _showWarning = true;
            _remainingTime = remaining;
          });
        }

        AppLogger.warning(
          'Session expiring in ${remaining.inMinutes} minutes',
          tag: 'SessionExpiryBanner',
        );
      } else {
        // More than 5 minutes remaining, hide warning
        if (mounted && _showWarning) {
          setState(() {
            _showWarning = false;
          });
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error checking token expiry',
        tag: 'SessionExpiryBanner',
        error: e,
      );
    }
  }

  Future<void> _extendSession() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      AppLogger.info(
        'User requested session extension',
        tag: 'SessionExpiryBanner',
      );

      // Force token refresh
      final newToken = await _tokenService.getAccessToken(forceRefresh: true);

      if (newToken != null) {
        AppLogger.success(
          'Session extended successfully',
          tag: 'SessionExpiryBanner',
        );

        if (mounted) {
          setState(() {
            _showWarning = false;
            _isRefreshing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Session extended successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      AppLogger.error(
        'Failed to extend session',
        tag: 'SessionExpiryBanner',
        error: e,
      );

      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to extend session. Please log in again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatRemainingTime() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showWarning) {
      // No warning, just show child
      return widget.child;
    }

    // Show warning banner above child
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Warning banner positioned at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 4,
            color: Colors.orange.shade700,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Session Expiring Soon',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your session expires in ${_formatRemainingTime()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _extendSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Stay Logged In',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}