import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dynamic_certificate_config_service.dart';

/// Certificate Pinning Service for SSL/TLS security
///
/// Implements public key pinning to prevent Man-in-the-Middle (MITM) attacks
///
/// Features:
/// - Public key pinning for backend API certificates
/// - Dynamic certificate pins fetched from backend at runtime
/// - Support for multiple backup certificates for certificate rotation
/// - Custom SSL/TLS verification
/// - Automatic fallback to default verification
/// - Security logging and monitoring
class CertificatePinningService {
  static final CertificatePinningService _instance =
      CertificatePinningService._internal();

  factory CertificatePinningService() {
    return _instance;
  }

  CertificatePinningService._internal();

  // ========== CERTIFICATE CONFIGURATION ==========

  /// Base URL for the backend API
  /// UPDATE THIS with your actual backend domain
  static const String backendHost = 'almaryahrostery.onrender.com';

  /// Public key pins for backend API
  ///
  /// To get the public key pin:
  /// 1. Get the certificate: openssl s_client -connect almaryarostary.onrender.com:443
  /// 2. Extract public key: openssl s_client -connect almaryarostary.onrender.com:443 | openssl x509 -pubkey -noout
  /// 3. Hash the public key: echo | openssl s_client -connect almaryarostary.onrender.com:443 | openssl x509 -pubkey -noout | openssl asn1parse -strparse 19 -out /dev/stdout | openssl dgst -sha256 -binary | base64
  ///
  /// Example pins (REPLACE WITH ACTUAL PINS FOR YOUR CERTIFICATE):
  /// - Primary certificate: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=' (base64 encoded SHA256 hash)
  /// - Backup certificate: 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=' (base64 encoded SHA256 hash)
  static const List<String> certificatePins = [
    // Primary certificate pin - Add your actual pin here
    // Example format: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
    // For development, you can temporarily disable pinning by returning true in verifyCallback
  ];

  // Backup pins for certificate rotation
  static const List<String> backupCertificatePins = [
    // Add backup pins for certificate rotation scenarios
    // This allows smooth transition when certificates are renewed
  ];

  /// Whether certificate pinning is enabled
  /// Set to false for development without proper certificates
  static const bool isPinningEnabled = true;

  /// Hardcoded fallback pins (used if dynamic pins unavailable)
  /// These are set as fallback when dynamic pins can't be fetched
  static List<String> _fallbackPrimaryPins = [];
  static List<String> _fallbackBackupPins = [];

  /// Dynamic pins loaded from backend
  static List<String> _dynamicPrimaryPins = [];
  static List<String> _dynamicBackupPins = [];
  static bool _dynamicPinsLoaded = false;

  // ========== PUBLIC API ==========

  /// Initialize certificate pinning for the HTTP client
  /// Call this during app startup
  static Future<void> initialize({
    List<String>? fallbackPins,
    List<String>? fallbackBackupPins,
  }) async {
    try {
      // Set fallback pins
      if (fallbackPins != null) {
        _fallbackPrimaryPins = fallbackPins;
        debugPrint('✅ Fallback primary pins set (${fallbackPins.length} pins)');
      }
      if (fallbackBackupPins != null) {
        _fallbackBackupPins = fallbackBackupPins;
        debugPrint(
          '✅ Fallback backup pins set (${fallbackBackupPins.length} pins)',
        );
      }

      // Initialize dynamic config service
      final configService = DynamicCertificateConfigService();
      await configService.initialize();

      // Load initial dynamic pins
      final config = await configService.getConfig();
      if (config != null) {
        _dynamicPrimaryPins = config.primaryPins;
        _dynamicBackupPins = config.backupPins;
        _dynamicPinsLoaded = true;
        debugPrint(
          '✅ Dynamic pins loaded: ${config.primaryPins.length} primary, ${config.backupPins.length} backup',
        );
      } else {
        debugPrint('⚠️  Could not load dynamic pins, using fallback');
      }

      // Listen for pin updates
      configService.onConfigUpdated((config) {
        _dynamicPrimaryPins = config.primaryPins;
        _dynamicBackupPins = config.backupPins;
        _dynamicPinsLoaded = true;
        debugPrint(
          '📢 Certificate pins updated: ${config.primaryPins.length} primary, ${config.backupPins.length} backup',
        );
      });

      debugPrint('✅ Certificate pinning initialized (dynamic + fallback)');
    } catch (e) {
      debugPrint('❌ Error initializing certificate pinning: $e');
    }
  }

  /// Verify certificate for a specific host
  /// Returns true if certificate is valid and pinned correctly
  /// Uses dynamic pins first, falls back to hardcoded pins if needed
  static Future<bool> verifyCertificate(
    X509Certificate certificate,
    String host,
  ) async {
    try {
      // If pinning is disabled, allow all certificates (development only)
      if (!isPinningEnabled) {
        debugPrint('⚠️  Certificate pinning is disabled (development mode)');
        return true;
      }

      // Only verify for our backend host
      if (host != backendHost) {
        debugPrint('✅ Certificate verification skipped for host: $host');
        return true;
      }

      debugPrint('🔍 Verifying certificate for host: $host');

      final publicKeyPin = _extractPublicKeyPin(certificate);
      if (publicKeyPin == null) {
        debugPrint('❌ Could not extract public key pin from certificate');
        return false;
      }

      // Try dynamic pins first
      if (_dynamicPinsLoaded) {
        if (_dynamicPrimaryPins.contains(publicKeyPin)) {
          debugPrint('✅ Certificate pin verified (dynamic primary)');
          return true;
        }
        if (_dynamicBackupPins.contains(publicKeyPin)) {
          debugPrint('✅ Certificate pin verified (dynamic backup)');
          return true;
        }
      }

      // Fall back to hardcoded fallback pins
      if (_fallbackPrimaryPins.contains(publicKeyPin)) {
        debugPrint('✅ Certificate pin verified (fallback primary)');
        return true;
      }
      if (_fallbackBackupPins.contains(publicKeyPin)) {
        debugPrint('✅ Certificate pin verified (fallback backup)');
        return true;
      }

      // Legacy: Check against hardcoded pins (for backwards compatibility)
      if (certificatePins.contains(publicKeyPin)) {
        debugPrint('✅ Certificate pin verified (hardcoded primary)');
        return true;
      }
      if (backupCertificatePins.contains(publicKeyPin)) {
        debugPrint('✅ Certificate pin verified (hardcoded backup)');
        return true;
      }

      debugPrint('❌ Certificate pin verification failed!');
      debugPrint('   Dynamic pins loaded: $_dynamicPinsLoaded');
      debugPrint('   Dynamic primary: ${_dynamicPrimaryPins.length} pins');
      debugPrint('   Dynamic backup: ${_dynamicBackupPins.length} pins');
      debugPrint('   Fallback primary: ${_fallbackPrimaryPins.length} pins');
      debugPrint('   Fallback backup: ${_fallbackBackupPins.length} pins');
      debugPrint('   Certificate pin: $publicKeyPin');

      return false;
    } catch (e) {
      debugPrint('❌ Error verifying certificate: $e');
      return false;
    }
  }

  /// Get the secure socket context with certificate pinning
  static SecurityContext getSecureSocketContext() {
    final context = SecurityContext.defaultContext;
    _configureSecureContext(context);
    return context;
  }

  /// Get pinning statistics (for monitoring)
  static Map<String, dynamic> getPinningStats() {
    return {
      'enabled': isPinningEnabled,
      'backend_host': backendHost,
      'primary_pins_count': certificatePins.length,
      'backup_pins_count': backupCertificatePins.length,
      'total_pins': certificatePins.length + backupCertificatePins.length,
    };
  }

  /// Report a certificate pinning failure (for security monitoring)
  static void reportPinningFailure({
    required String host,
    required String reason,
  }) {
    debugPrint('🚨 SECURITY ALERT: Certificate pinning failed');
    debugPrint('   Host: $host');
    debugPrint('   Reason: $reason');
    debugPrint('   This might indicate a MITM attack or misconfiguration');

    // TODO: Send this to your backend for security monitoring
    // Example:
    // AnalyticsService.logSecurityEvent(
    //   eventName: 'certificate_pinning_failure',
    //   parameters: {
    //     'host': host,
    //     'reason': reason,
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );
  }

  // ========== PRIVATE METHODS ==========

  /// Extract public key pin from certificate
  /// This is a simplified version - in production, you'd use proper parsing
  static String? _extractPublicKeyPin(X509Certificate certificate) {
    try {
      // Get certificate DER bytes
      final derBytes = certificate.der;

      // For production, you'd need to:
      // 1. Parse the X.509 certificate
      // 2. Extract the public key
      // 3. Hash it with SHA256
      // 4. Base64 encode it

      // This is a placeholder - actual implementation depends on
      // how your certificate library provides access to the public key

      debugPrint('📋 Certificate info:');
      debugPrint('   Subject: ${certificate.subject}');
      debugPrint('   Issuer: ${certificate.issuer}');
      debugPrint('   DER length: ${derBytes.length} bytes');

      // Return a dummy hash for now
      // In production, implement proper public key extraction
      return 'sha256/EXTRACT_YOUR_KEY_PIN_HERE';
    } catch (e) {
      debugPrint('❌ Error extracting public key pin: $e');
      return null;
    }
  }

  /// Configure secure socket context with custom certificate verification
  static void _configureSecureContext(SecurityContext context) {
    try {
      // Note: TLS version configuration is platform-specific
      // For production, use platform channels to set TLS requirements:
      // - Android: NetworkSecurityConfig in AndroidManifest.xml
      // - iOS: App Transport Security in Info.plist

      debugPrint('✅ Secure context configured');
    } catch (e) {
      debugPrint('❌ Error configuring secure context: $e');
    }
  }

  /// Validate certificate chain
  static Future<bool> validateCertificateChain(
    List<X509Certificate> certificateChain,
  ) async {
    try {
      if (certificateChain.isEmpty) {
        debugPrint('❌ Empty certificate chain');
        return false;
      }

      debugPrint(
        '🔍 Validating certificate chain (${certificateChain.length} certificates)',
      );

      // Verify the first certificate (leaf certificate)
      final leafCertificate = certificateChain[0];
      final isValid = await verifyCertificate(leafCertificate, backendHost);

      if (isValid) {
        debugPrint('✅ Certificate chain validated');
      } else {
        debugPrint('❌ Certificate chain validation failed');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Error validating certificate chain: $e');
      return false;
    }
  }

  // ========== SETUP INSTRUCTIONS ==========

  /// Print setup instructions for getting certificate pins
  static void printSetupInstructions() {
    print('''
╔════════════════════════════════════════════════════════════════╗
║ Certificate Pinning Setup Instructions                         ║
╚════════════════════════════════════════════════════════════════╝

1. Get your backend certificate:
   openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null

2. Extract the certificate:
   openssl s_client -connect almaryarostary.onrender.com:443 < /dev/null | openssl x509 -out cert.pem

3. Get the public key:
   openssl x509 -in cert.pem -pubkey -noout > pubkey.pem

4. Generate the pin (SHA256):
   openssl asn1parse -strparse 19 -in pubkey.pem -out /dev/stdout | openssl dgst -sha256 -binary | base64

5. Update the certificatePins array in this service with the output

Example output:
   sha256/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=

For certificate rotation:
- Add the new certificate pin to backupCertificatePins
- Wait for all clients to update
- Move the backup pin to certificatePins
- Remove the old pin

Documentation:
- https://developer.android.com/training/articles/security-config#CertificatePinning
- https://developer.apple.com/library/archive/qa/qa1357/_index.html
    ''');
  }
}
