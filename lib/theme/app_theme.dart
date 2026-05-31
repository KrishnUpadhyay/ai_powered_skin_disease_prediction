import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Elegant Brand Light Theme Palette
  static const Color lightPrimaryColor = Color(0xFF00897B);    // Premium Teal
  static const Color lightSecondaryColor = Color(0xFF00ACC1);  // Cyan
  static const Color lightAccentColor = Color(0xFF7E57C2);     // Soft Clinical Purple
  static const Color lightBackgroundColor = Color(0xFFF5F7FA);  // Clinical Off-White
  static const Color lightCardColor = Colors.white;
  static const Color lightTextDark = Color(0xFF2C3E50);
  static const Color lightTextLight = Color(0xFF7F8C8D);

  // 🌌 Unique Cyber Neon Dark Theme Palette (Clinical Modernism)
  static const Color darkPrimaryColor = Color(0xFF00E5FF);     // Glowing Neon Cyan
  static const Color darkSecondaryColor = Color(0xFF7C4DFF);   // Cyber Indigo/Purple
  static const Color darkAccentColor = Color(0xFFFF4081);      // Neon Rose
  static const Color darkBackgroundColor = Color(0xFF0A0F1D);  // Sophisticated Slate Obsidian
  static const Color darkCardColor = Color(0xFF151D30);        // Futuristic Clinical Blue-Grey
  static const Color darkTextDark = Color(0xFFECEFF1);         // Clear White-Silver
  static const Color darkTextLight = Color(0xFF90A4AE);        // Soft Steel Blue

  // Fallback direct references
  static const Color primaryColor = lightPrimaryColor;
  static const Color secondaryColor = lightSecondaryColor;
  static const Color accentColor = lightAccentColor;
  static const Color textDarkColor = lightTextDark;
  static const Color textLightColor = lightTextLight;

  // ☀️ High-Contrast Light Theme Config
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimaryColor,
        primary: lightPrimaryColor,
        secondary: lightSecondaryColor,
        tertiary: lightAccentColor,
        surface: lightCardColor,
        brightness: Brightness.light,
      ).copyWith(
        background: lightBackgroundColor,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimaryColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: lightPrimaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: lightPrimaryColor, width: 1.5),
          foregroundColor: lightPrimaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: lightTextDark, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: lightTextDark, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: lightTextDark, fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: lightTextDark, fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: lightTextDark, fontSize: 14.5, height: 1.4),
        bodyMedium: TextStyle(color: lightTextLight, fontSize: 13.5, height: 1.4),
      ),
    );
  }

  // 🌙 Ultra-Premium Cyber Neon Dark Theme Config (State-of-the-Art)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryColor,
        primary: darkPrimaryColor,
        secondary: darkSecondaryColor,
        tertiary: darkAccentColor,
        surface: darkCardColor,
        brightness: Brightness.dark,
      ).copyWith(
        background: darkBackgroundColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 4,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: darkPrimaryColor,
          foregroundColor: darkBackgroundColor, // dark background text on neon cyan looks extremely premium
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: darkPrimaryColor, width: 1.5),
          foregroundColor: darkPrimaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: darkTextDark, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: darkTextDark, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: darkTextDark, fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: darkTextDark, fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkTextDark, fontSize: 14.5, height: 1.4),
        bodyMedium: TextStyle(color: darkTextLight, fontSize: 13.5, height: 1.4),
      ),
    );
  }
}
