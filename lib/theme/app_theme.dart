import 'package:flutter/material.dart';

class AppTheme {
  // 브랜드 컬러
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFFFF6B35);
  static const Color accent = Color(0xFF00C896);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      secondary: secondary,
      surface: surface,
    ),
    fontFamily: 'NotoSansKR',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: textPrimary,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: textPrimary,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: textPrimary,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 16,
        color: textPrimary,
        height: 1.8,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 14,
        color: textSecondary,
        height: 1.6,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    fontFamily: 'NotoSansKR',
  );
}
