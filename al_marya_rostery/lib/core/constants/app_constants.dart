/// App-wide constants for ALMARYAH ROSTERY
class AppConstants {
  // API Endpoints - Environment Configuration
  // Set _useProduction to true for production Render.com backend (connects to MongoDB Atlas)
  // Set _useProduction to false for local development backend
  static const bool _useProduction = true; // ✅ Using production backend

  static String get baseUrl => _useProduction
      ? 'https://almaryahrostery.onrender.com' // Production Render.com backend (connects to MongoDB Atlas)
      : 'http://192.168.0.148:5001'; // Local development backend (use your computer's IP, not localhost)

  // Environment info for debugging
  static String get environment => _useProduction
      ? 'Production (Render.com → MongoDB Atlas)'
      : 'Local Development';

  static const String coffeeEndpoint = '/api/coffees';
  static const String categoriesEndpoint = '/api/categories';
  static const String slidersEndpoint = '/api/sliders';
  static const String cartEndpoint = '/cart';
  static const String ordersEndpoint = '/orders';
  static const String authEndpoint = '/api/auth';

  // New Feature Endpoints
  static const String reviewsEndpoint = '/api/reviews';
  static const String loyaltyEndpoint = '/api/loyalty';
  static const String referralsEndpoint = '/api/referrals';
  static const String subscriptionsEndpoint = '/api/subscriptions';

  // Payment Configuration
  // ⚠️ Stripe key is now fetched from backend via ConfigService
  // This prevents exposing sensitive keys in the app source code

  // App Info
  static const String appName = 'ALMARYAH ROSTERY';
  static const String appVersion = '1.0.0';

  // Currency
  static const String currencySymbol = 'AED'; // UAE Dirham Code
  static const String currencyCode = 'AED';

  // Asset Paths
  static const String logoPath = 'assets/images/common/logo.png';
  static const String defaultProfilePic = 'assets/images/default_profile.png';

  // Other constants
  static const int defaultTimeout =
      60; // seconds - increased for Render.com cold starts
}
