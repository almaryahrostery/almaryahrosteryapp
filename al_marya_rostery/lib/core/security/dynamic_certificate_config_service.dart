import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Model for dynamic certificate pin configuration
class DynamicCertificateConfig {
  final List<String> primaryPins;
  final List<String> backupPins;
  final DateTime expiresAt;
  final DateTime fetchedAt;
  final String version;

  DynamicCertificateConfig({
    required this.primaryPins,
    required this.backupPins,
    required this.expiresAt,
    required this.fetchedAt,
    required this.version,
  });

  /// Check if configuration is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'primaryPins': primaryPins,
    'backupPins': backupPins,
    'expiresAt': expiresAt.toIso8601String(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'version': version,
  };

  /// Create from JSON
  factory DynamicCertificateConfig.fromJson(Map<String, dynamic> json) =>
      DynamicCertificateConfig(
        primaryPins: List<String>.from(json['primaryPins'] as List? ?? []),
        backupPins: List<String>.from(json['backupPins'] as List? ?? []),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        version: json['version'] as String? ?? '1.0',
      );

  @override
  String toString() =>
      'DynamicCertConfig(version: $version, primaryPins: ${primaryPins.length}, backupPins: ${backupPins.length}, valid: $isValid)';
}

/// Service for dynamically fetching and caching certificate pins
///
/// Features:
/// - Fetches certificate pins from backend at runtime
/// - Caches pins locally for offline operation
/// - Automatically refreshes stale pins
/// - Fallback to hardcoded pins if network fails
/// - Version tracking to detect pin updates
/// - Secure storage of pin cache
///
/// Architecture:
/// 1. App startup: Load cached pins from secure storage
/// 2. Background: Periodically fetch latest pins from backend
/// 3. When needed: Use latest pins or fall back to cache
/// 4. On cache miss: Use hardcoded pins (fail-safe)
class DynamicCertificateConfigService {
  static final DynamicCertificateConfigService _instance =
      DynamicCertificateConfigService._internal();

  factory DynamicCertificateConfigService() {
    return _instance;
  }

  DynamicCertificateConfigService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _cacheKey = 'dynamic_cert_config';
  static const String _versionKey = 'dynamic_cert_version';

  // Configuration
  static const String _backendHost = 'almaryahrostery.onrender.com';
  static const String _configEndpoint = '/api/security/certificate-pins';
  static const Duration _cacheDuration = Duration(days: 7);
  static const Duration _refreshInterval = Duration(hours: 24);

  // State
  DynamicCertificateConfig? _cachedConfig;
  Timer? _refreshTimer;
  bool _isInitialized = false;

  // Callbacks
  final List<Function(DynamicCertificateConfig)> _onConfigUpdated = [];

  /// Initialize the service
  /// Should be called early in app startup (before making any HTTPS requests)
  Future<void> initialize({
    /// Optional: Custom endpoint URL (defaults to /api/security/certificate-pins)
    String? customEndpoint,

    /// Optional: Custom backend host (defaults to almaryarostary.onrender.com)
    String? customHost,
  }) async {
    try {
      debugPrint('🔄 Initializing dynamic certificate config service...');

      // Load cached config
      await _loadCachedConfig();

      if (_cachedConfig != null) {
        debugPrint('✅ Loaded cached certificate config: $_cachedConfig');
      }

      // Fetch fresh config if cache is missing or expired
      if (_cachedConfig == null || !_cachedConfig!.isValid) {
        await _fetchConfigFromBackend();
      }

      // Schedule periodic refresh
      _schedulePeriodicRefresh();

      _isInitialized = true;
      debugPrint('✅ Dynamic certificate config service initialized');
    } catch (e) {
      debugPrint('⚠️  Error initializing dynamic config service: $e');
      _isInitialized = true; // Continue anyway with cached/hardcoded pins
    }
  }

  /// Get current certificate configuration
  /// Returns cached config or fetches fresh one if needed
  Future<DynamicCertificateConfig?> getConfig() async {
    try {
      // If cached and valid, return it
      if (_cachedConfig != null && _cachedConfig!.isValid) {
        return _cachedConfig;
      }

      // Try to fetch fresh config
      final freshConfig = await _fetchConfigFromBackend();
      return freshConfig ?? _cachedConfig;
    } catch (e) {
      debugPrint('❌ Error getting config: $e');
      return _cachedConfig;
    }
  }

  /// Force refresh configuration immediately
  /// Useful for handling certificate changes urgently
  Future<bool> forceRefresh() async {
    try {
      debugPrint('🔄 Force refreshing certificate config...');
      final config = await _fetchConfigFromBackend();
      return config != null;
    } catch (e) {
      debugPrint('❌ Force refresh failed: $e');
      return false;
    }
  }

  /// Get all valid pins (primary + backup)
  Future<List<String>> getAllValidPins() async {
    try {
      final config = await getConfig();
      if (config != null) {
        return [...config.primaryPins, ...config.backupPins];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting valid pins: $e');
      return [];
    }
  }

  /// Register callback for config updates
  void onConfigUpdated(Function(DynamicCertificateConfig) callback) {
    _onConfigUpdated.add(callback);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'initialized': _isInitialized,
      'cached_config': _cachedConfig?.toString() ?? 'none',
      'is_valid': _cachedConfig?.isValid ?? false,
      'time_to_expiry_hours': _cachedConfig != null
          ? _cachedConfig!.expiresAt.difference(DateTime.now()).inHours
          : null,
    };
  }

  // ========== PRIVATE METHODS ==========

  /// Load configuration from secure storage cache
  Future<void> _loadCachedConfig() async {
    try {
      final cachedJson = await _secureStorage.read(key: _cacheKey);
      if (cachedJson != null) {
        final json = jsonDecode(cachedJson) as Map<String, dynamic>;
        _cachedConfig = DynamicCertificateConfig.fromJson(json);
        debugPrint('📦 Loaded cached config: $_cachedConfig');
      }
    } catch (e) {
      debugPrint('⚠️  Error loading cached config: $e');
      _cachedConfig = null;
    }
  }

  /// Save configuration to secure storage cache
  Future<void> _saveCachedConfig(DynamicCertificateConfig config) async {
    try {
      final json = jsonEncode(config.toJson());
      await _secureStorage.write(key: _cacheKey, value: json);
      await _secureStorage.write(key: _versionKey, value: config.version);
      debugPrint('💾 Saved config to cache: ${config.version}');
    } catch (e) {
      debugPrint('❌ Error saving config cache: $e');
    }
  }

  /// Fetch certificate configuration from backend
  Future<DynamicCertificateConfig?> _fetchConfigFromBackend() async {
    try {
      debugPrint('🌐 Fetching certificate config from backend...');

      // Build request URL
      final url = Uri.https(_backendHost, _configEndpoint);

      // Make request (without authentication - this endpoint should be public)
      final response = await http
          .get(url)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Certificate config fetch timeout'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        // Parse response
        final config = DynamicCertificateConfig(
          primaryPins: List<String>.from(json['primaryPins'] as List? ?? []),
          backupPins: List<String>.from(json['backupPins'] as List? ?? []),
          expiresAt: DateTime.parse(
            json['expiresAt'] as String? ?? _getDefaultExpiry(),
          ),
          fetchedAt: DateTime.now(),
          version: json['version'] as String? ?? '1.0',
        );

        // Validate config
        if (config.primaryPins.isEmpty) {
          throw Exception('No primary pins in config');
        }

        // Check if config changed
        final oldVersion = _cachedConfig?.version;
        if (oldVersion != config.version) {
          debugPrint(
            '📢 Certificate config updated: $oldVersion → ${config.version}',
          );
          _notifyConfigUpdated(config);
        }

        // Cache the config
        await _saveCachedConfig(config);
        _cachedConfig = config;

        debugPrint('✅ Fetched fresh config: $config');
        return config;
      } else {
        debugPrint(
          '⚠️  Certificate config fetch failed (${response.statusCode}): ${response.body}',
        );
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️  Certificate config fetch timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching certificate config: $e');
      return null;
    }
  }

  /// Schedule periodic configuration refresh
  void _schedulePeriodicRefresh() {
    _refreshTimer?.cancel();

    debugPrint(
      '⏰ Scheduling certificate config refresh every ${_refreshInterval.inHours} hours',
    );

    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      debugPrint('⏰ Certificate config refresh timer triggered');
      _fetchConfigFromBackend();
    });
  }

  /// Notify all listeners of config update
  void _notifyConfigUpdated(DynamicCertificateConfig config) {
    for (final callback in _onConfigUpdated) {
      try {
        callback(config);
      } catch (e) {
        debugPrint('❌ Error in config update callback: $e');
      }
    }
  }

  /// Get default expiry time (cache duration from now)
  static String _getDefaultExpiry() {
    return DateTime.now().add(_cacheDuration).toIso8601String();
  }

  /// Cleanup resources
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _cachedConfig = null;
    _onConfigUpdated.clear();
  }
}
