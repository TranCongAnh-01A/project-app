import 'package:flutter/material.dart';

/// Theme MoneJour — thiết kế hiện đại, tối giản.
///
/// Palette lấy cảm hứng từ finance apps (Mint, YNAB):
///   - Xanh lá đậm (primary): ổn định, tài chính
///   - Cam ấm (accent): hành động, CTA
///   - Nền tối: dễ đọc, tiết kiệm pin OLED
class AppTheme {
  // ── Colors ──
  static const primaryColor = Color(0xFF10B981);
  static const secondaryColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const surfaceDark = Color(0xFF1E1E2E);
  static const surfaceLight = Color(0xFFF8FAFC);
  static const cardDark = Color(0xFF2A2A3E);
  static const cardLight = Color(0xFFFFFFFF);

  /// Theme sáng
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor: surfaceLight,
        cardTheme: const CardThemeData(
          color: cardLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        fontFamily: 'Roboto',
      );

  /// Theme tối
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor: surfaceDark,
        cardTheme: const CardThemeData(
          color: cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        fontFamily: 'Roboto',
      );
}
