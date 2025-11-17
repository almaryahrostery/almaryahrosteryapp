import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'core/services/firebase_analytics_service.dart';
import 'core/services/firebase_performance_service.dart';
import 'core/theme/almaryah_theme.dart';
import 'utils/app_router.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/providers/admin_user_provider.dart';
import 'features/admin/presentation/providers/firebase_user_provider.dart';
import 'features/admin/presentation/providers/product_provider.dart';
import 'features/admin/presentation/providers/category_provider.dart';
import 'features/admin/presentation/providers/slider_provider.dart';
import 'features/admin/presentation/providers/quick_category_provider.dart';
import 'features/admin/presentation/providers/user_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'data/repositories/firebase_auth_repository_impl.dart';
import 'data/datasources/firebase_auth_service.dart';
import 'features/coffee/presentation/providers/coffee_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'core/providers/language_provider.dart';
import 'core/services/product_api_service.dart';
import 'core/services/category_api_service.dart';
import 'core/services/slider_api_service.dart';
import 'core/services/user_api_service.dart';
import 'core/services/gift_set_api_service.dart';
import 'providers/location_provider.dart';
import 'providers/address_provider.dart';
import 'providers/gift_set_provider.dart';
import 'features/subscriptions/presentation/providers/subscriptions_provider.dart';
import 'l10n/app_localizations.dart';
import 'core/error/global_error_handler.dart';
import 'core/network/network_manager.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'services/fcm_service.dart';
import 'core/services/config_service.dart';
import 'core/services/auth_token_service.dart';
import 'core/widgets/session_expiry_banner.dart';
import 'core/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling
  GlobalErrorHandler.initialize();

  // Initialize network manager
  await NetworkManager().initialize();

  // 🔥 ONE-TIME FIX: Force clear all tokens to fix Firebase/Backend JWT mismatch
  // Users must log in again to get proper backend JWT tokens (30 days)
  try {
    final authTokenService = AuthTokenService();
    await authTokenService.clearTokens();
    if (kDebugMode) {
      print('🧹 Cleared all tokens - fresh login required for backend JWT');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Token clear failed: $e');
    }
  }

  // Skip Stripe initialization at app launch to speed up startup
  // Stripe key will be fetched lazily when user enters checkout
  if (kDebugMode) {
    print('⏭️  Skipping Stripe initialization at launch (will load on-demand)');
  }

  // Initialize Firebase with error handling

  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    if (kDebugMode) {
      print('✅ Firebase initialized');
    }
  } catch (e) {
    // Firebase might already be initialized
    if (e.toString().contains('duplicate-app')) {
      firebaseInitialized = true;
      if (kDebugMode) {
        print('✅ Firebase already initialized');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Firebase initialization error: $e');
      }
      runApp(MyApp(firebaseInitialized: false));
      return;
    }
  }

  // Only proceed with Firebase services if Firebase is initialized
  if (firebaseInitialized) {
    // Initialize Firebase Crashlytics
    try {
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      if (kDebugMode) {
        print('✅ Crashlytics initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Crashlytics failed: $e');
      }
    }

    // Initialize Firebase Performance Monitoring
    try {
      await FirebasePerformanceService().initialize();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Performance Monitoring failed: $e');
      }
    }

    // Initialize FCM
    try {
      await FCMService().initialize();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM failed: $e');
      }
    }
  }

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, this.firebaseInitialized = true});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(FirebaseAuthRepositoryImpl(FirebaseAuthService())),
        ),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => AdminUserProvider()),
        ChangeNotifierProvider(create: (context) => FirebaseUserProvider()),
        ChangeNotifierProvider(create: (context) => CoffeeProvider()),
        ChangeNotifierProvider(
          create: (context) => ProductProvider(ProductApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryProvider(categoryApiService: CategoryApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SliderProvider(sliderApiService: SliderApiService()),
        ),
        ChangeNotifierProvider(create: (context) => QuickCategoryProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProvider(userApiService: UserApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => AddressProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => GiftSetProvider(GiftSetApiService()),
        ),
        ChangeNotifierProvider(create: (context) => SubscriptionsProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          if (languageProvider.isLoading) {
            return MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'ALMARYAH ROSTERY',
            theme: AlmaryahTheme.light,
            darkTheme: AlmaryahTheme.dark,
            themeMode: ThemeMode.system,
            locale: languageProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageProvider.supportedLocales,
            localeResolutionCallback: LanguageProvider.localeResolutionCallback,
            home: Directionality(
              textDirection: languageProvider.textDirection,
              child: const SplashPage(),
            ),
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.textDirection,
                child: OfflineBanner(
                  child: SessionExpiryBanner(
                    child: child ?? Container(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
