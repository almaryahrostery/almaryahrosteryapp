import 'package:flutter/material.dart';

/// AlmaryahTheme provides elegant, premium theme data for Almaryah Rostery
/// Based on the brand's olive gold and warm beige color palette
class AlmaryahTheme {
  // Brand Color Palette
  static const Color _primaryOliveGold = Color(0xFFA89A6A);
  static const Color _secondaryLightGold = Color(0xFFCBBE8C);
  static const Color _backgroundWarmBeige = Color(0xFFEDE9E1);
  static const Color _textPrimaryDarkCharcoal = Color(0xFF2C2C2C);
  static const Color _textSecondaryMutedGray = Color(0xFF6E6E6E);
  static const Color _white = Color(0xFFFFFFFF);

  // Dark Mode Colors
  static const Color _darkBackgroundEspresso = Color(0xFF1E1C18);
  static const Color _darkSurfaceDeepBrown = Color(0xFF2A2824);
  static const Color _darkTextLight = Color(0xFFF5F5F5);
  static const Color _darkTextMuted = Color(0xFFC0C0C0);

  /// Light Theme Configuration
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _backgroundWarmBeige,
      canvasColor: _primaryOliveGold, // Drawer background color
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: _primaryOliveGold,
        secondary: _secondaryLightGold,
        surface: _backgroundWarmBeige, // Changed from background
        onPrimary: _white,
        onSecondary: _textPrimaryDarkCharcoal,
        onSurface: _textPrimaryDarkCharcoal, // Changed from onBackground
        error: Color(0xFFD32F2F),
        onError: _white,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryOliveGold,
        foregroundColor: _white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: _white),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: _white,
        elevation: 4,
        shadowColor: Color.fromRGBO(168, 154, 106, 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryOliveGold,
          foregroundColor: _white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryOliveGold,
          side: const BorderSide(color: _primaryOliveGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryOliveGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      // Text Theme (Using system fonts as fallback until custom fonts are added)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: _textPrimaryDarkCharcoal,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDarkCharcoal,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDarkCharcoal,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _textPrimaryDarkCharcoal,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDarkCharcoal,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDarkCharcoal,
        ),
        titleLarge: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _textPrimaryDarkCharcoal,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textPrimaryDarkCharcoal,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _textSecondaryMutedGray,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: _textPrimaryDarkCharcoal,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: _textSecondaryMutedGray,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _textSecondaryMutedGray,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _textPrimaryDarkCharcoal,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textSecondaryMutedGray,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _textSecondaryMutedGray,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _secondaryLightGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _secondaryLightGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryOliveGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        labelStyle: const TextStyle(color: _textSecondaryMutedGray),
        hintStyle: const TextStyle(color: _textSecondaryMutedGray),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryOliveGold,
        foregroundColor: _white,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _white,
        selectedItemColor: _primaryOliveGold,
        unselectedItemColor: _textSecondaryMutedGray,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _secondaryLightGold,
        thickness: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primaryOliveGold,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _secondaryLightGold.withValues(alpha: 0.3),
        selectedColor: _primaryOliveGold,
        labelStyle: const TextStyle(color: _textPrimaryDarkCharcoal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// Dark Theme Configuration
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackgroundEspresso,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: _secondaryLightGold,
        secondary: _primaryOliveGold,
        surface: _darkBackgroundEspresso, // Changed from background
        onPrimary: _darkBackgroundEspresso,
        onSecondary: _darkTextLight,
        onSurface: _darkTextLight, // Changed from onBackground
        error: Color(0xFFEF5350),
        onError: _darkBackgroundEspresso,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurfaceDeepBrown,
        foregroundColor: _secondaryLightGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _secondaryLightGold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: _secondaryLightGold),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: _darkSurfaceDeepBrown,
        elevation: 4,
        shadowColor: Color.fromRGBO(0, 0, 0, 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondaryLightGold,
          foregroundColor: _darkBackgroundEspresso,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _secondaryLightGold,
          side: const BorderSide(color: _secondaryLightGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondaryLightGold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      // Text Theme (Using system fonts as fallback until custom fonts are added)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: _darkTextLight,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _darkTextLight,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkTextLight,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _darkTextLight,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _darkTextLight,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkTextLight,
        ),
        titleLarge: TextStyle(
          fontFamily: 'serif', // Fallback to system serif
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _darkTextLight,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _darkTextLight,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _darkTextMuted,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: _darkTextLight,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: _darkTextMuted,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _darkTextMuted,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _darkTextLight,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkTextMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _darkTextMuted,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceDeepBrown,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryOliveGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryOliveGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _secondaryLightGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        labelStyle: const TextStyle(color: _darkTextMuted),
        hintStyle: const TextStyle(color: _darkTextMuted),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondaryLightGold,
        foregroundColor: _darkBackgroundEspresso,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurfaceDeepBrown,
        selectedItemColor: _secondaryLightGold,
        unselectedItemColor: _darkTextMuted,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: _primaryOliveGold,
        thickness: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _secondaryLightGold,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _primaryOliveGold.withValues(alpha: 0.3),
        selectedColor: _secondaryLightGold,
        labelStyle: const TextStyle(color: _darkTextLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
