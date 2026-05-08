import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme MoneJour — palette Minimalist Blue Pastel & Neutral Gray.
///
/// Bảng màu từ yêu cầu:
///   - Nền chính (Scaffold): #F2F4F7 (xám rất nhạt)
///   - Thẻ/Surface (Card/Header): #FFFFFF
///   - Primary (Chủ đạo): #6C5CE7 (Xanh dương pastel đậm)
///   - Primary Light: #A29BFE
///   - Thu nhập (Income): #00B894 (Xanh lá pastel)
///   - Chi tiêu (Expense): #E17055 (Cam pastel)
///   - Main Text: #2D3436
///   - Secondary Text: #718096
///   - Date/Muted Text: #A0AEC0
///   - Viền danh mục/input: #E2E8F0 / #CBD5E0
class AppTheme {
  // ── Palette chính ──
  static const primaryPastel = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFFA29BFE);
  
  static const scaffoldBg = Color(0xFFF2F4F7);
  static const cardBg = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFE2E8F0);
  static const inputBorderColor = Color(0xFFCBD5E0);
  static const surfaceWhite = Color(0xFFFFFFFF);

  // ── Màu ngữ nghĩa ──
  static const incomeGreen = Color(0xFF00B894);  // Hiển thị số tiền thu nhập
  static const expenseRed = Color(0xFFE17055);   // Hiển thị số tiền chi tiêu
  static const warningAmber = Color(0xFFF5A623); // Cảnh báo ngưỡng budget
  static const dangerRed = Color(0xFFEF4444);    // Hành động nguy hiểm (xóa, lỗi)
  static const actionGreen = Color(0xFF10B981);  // Nút xác nhận/lưu tích cực

  // ── Text ──
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF718096);
  static const textHint = Color(0xFFA0AEC0);
  static const textMuted = Color(0xFF636E72); // Cho unselected tab

  /// Theme chính (Minimalist Light)
  static ThemeData get minimalistLight {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',

      colorScheme: const ColorScheme.light(
        primary: primaryPastel,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: textPrimary,
        secondary: primaryPastel,
        onSecondary: Colors.white,
        secondaryContainer: scaffoldBg,
        onSecondaryContainer: textPrimary,
        surface: cardBg,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: scaffoldBg,
        outline: borderColor,
        error: expenseRed,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: scaffoldBg,

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Bo góc vừa phải
          side: const BorderSide(color: borderColor, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Navigation Bar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryPastel.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryPastel,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryPastel, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),

      // ── FilledButton ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryPastel,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Bo góc 8px theo yêu cầu
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPastel,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryPastel,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1.0,
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPastel, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
      ),
    );
  }

  static const darkScaffoldBg = Color(0xFF121212);
  static const darkCardBg = Color(0xFF1E1E1E);
  static const darkBorderColor = Color(0xFF2C2C2C);
  static const darkTextPrimary = Color(0xFFF8F9FA);
  static const darkTextSecondary = Color(0xFFA0AEC0);

  static ThemeData get minimalistDark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: primaryPastel,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: primaryPastel,
        onSecondary: Colors.white,
        secondaryContainer: darkScaffoldBg,
        onSecondaryContainer: darkTextPrimary,
        surface: darkCardBg,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        surfaceContainerHighest: darkScaffoldBg,
        outline: darkBorderColor,
        error: expenseRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkScaffoldBg,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkCardBg,
        foregroundColor: darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorderColor, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryPastel.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryPastel,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryPastel, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryPastel,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPastel,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryPastel,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderColor,
        thickness: 1.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryPastel, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
      ),
    );
  }

  // Để tương thích
  static ThemeData get light => minimalistLight;
  static ThemeData get dark => minimalistDark;
}
