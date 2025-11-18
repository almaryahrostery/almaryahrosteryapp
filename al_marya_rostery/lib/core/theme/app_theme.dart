import 'package:flutter/material.dart';

/// AppTheme provides backward compatibility while using Almaryah brand colors
class AppTheme {
  // Almaryah Brand Color Palette (Olive Gold Theme)
  static const Color primaryBrown = Color(
    0xFFA89A6A,
  ); // Changed: Olive Gold (was Saddle Brown)
  static const Color primaryLightBrown = Color(
    0xFFCBBE8C,
  ); // Changed: Light Gold (was Tan)
  static const Color accentAmber = Color(
    0xFFCBBE8C,
  ); // Changed: Light Gold (was Gold)
  static const Color accentBrown = Color(
    0xFFA89A6A,
  ); // Changed: Olive Gold (was Peru)
  static const Color secondaryBrown = Color(
    0xFFA89A6A,
  ); // Changed: Olive Gold (was Sienna)
  static const Color backgroundCream = Color(
    0xFFEDE9E1,
  ); // Changed: Warm Beige (was Light Cream)
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(
    0xFF2C2C2C,
  ); // Changed: Dark Charcoal (was Brown)
  static const Color textMedium = Color(
    0xFF6E6E6E,
  ); // Changed: Muted Gray (was Brown)
  static const Color textLight = Color(
    0xFF8B7355,
  ); // Kept similar for compatibility

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBrown, // Now Olive Gold
      scaffoldBackgroundColor: backgroundCream, // Now Warm Beige
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryBrown, // Olive Gold
        secondary: primaryLightBrown, // Light Gold
        surface: surfaceWhite,
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: textDark,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: surfaceWhite,
        elevation: 4,
        shadowColor: Color.fromRGBO(139, 69, 19, 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
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

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textMedium,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMedium,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textMedium,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textLight,
          height: 1.4,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLightBrown),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLightBrown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBrown, width: 2),
        ),
        labelStyle: const TextStyle(color: textMedium),
        hintStyle: const TextStyle(color: textLight),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentAmber,
        foregroundColor: textDark,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: primaryBrown,
        unselectedItemColor: textLight,
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: primaryLightBrown,
        thickness: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBrown,
      ),
    );
  }

  // Dark theme (optional future enhancement)
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: const ColorScheme.dark(
        primary: primaryBrown,
        secondary: accentAmber,
        surface: Color(0xFF2A2A2A),
      ),
    );
  }
}
