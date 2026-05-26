import 'package:flutter/material.dart';

/// ألوان جمعية حقّنا - مطابقة للهوية البصرية لتطبيق الويب
class HaqqunaColors {
  static const Color primary = Color(0xFF1C6B85);
  static const Color accent = Color(0xFF4FBFD6);
  static const Color dark = Color(0xFF0E3D4D);
  static const Color light = Color(0xFFE8F4F8);
  static const Color cream = Color(0xFFFDFBF7);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);
  static const Color success = Color(0xFF198754);
}

class HaqqunaTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: HaqqunaColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HaqqunaColors.primary,
        primary: HaqqunaColors.primary,
        secondary: HaqqunaColors.accent,
      ),
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: HaqqunaColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HaqqunaColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: HaqqunaColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    return light().copyWith(brightness: Brightness.dark);
  }
}
