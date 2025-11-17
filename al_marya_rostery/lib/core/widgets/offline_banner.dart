import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// Offline Detection Banner
/// 
/// Monitors network connectivity and shows a banner when offline.
/// Auto-hides when connection is restored.
/// Prevents users from attempting actions that require internet.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  
  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Timer? _connectivityTimer;
  bool _isOnline = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check connectivity every 10 seconds
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
    
    // Initial check
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      
      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (mounted && _isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
        });

        if (isOnline) {
          AppLogger.success(
            'Internet connection restored',
            tag: 'OfflineBanner',
          );
        } else {
          AppLogger.warning(
            'No internet connection',
            tag: 'OfflineBanner',
          );
        }
      }
    } on SocketException catch (_) {
      if (mounted && _isOnline) {
        setState(() {
          _isOnline = false;
        });
        AppLogger.warning('No internet connection', tag: 'OfflineBanner');
      }
    } on TimeoutException catch (_) {
      if (mounted && _isOnline) {
        setState(() {
          _isOnline = false;
        });
        AppLogger.warning('Connection timeout', tag: 'OfflineBanner');
      }
    } catch (e) {
      AppLogger.error(
        'Error checking connectivity',
        tag: 'OfflineBanner',
        error: e,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        if (!_isOnline)
          Material(
            elevation: 4,
            color: Colors.red.shade700,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No Internet Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _checkConnectivity,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Retry',
                              style: TextStyle(fontSize: 12),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}

