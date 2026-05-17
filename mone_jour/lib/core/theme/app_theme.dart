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

  // ── Dark mode palette ──
  static const darkScaffoldBg = Color(0xFF121212);
  static const darkCardBg = Color(0xFF1E1E1E);
  static const darkBorderColor = Color(0xFF2C2C2C);
  static const darkTextPrimary = Color(0xFFF8F9FA);
  static const darkTextSecondary = Color(0xFFA0AEC0);

  /// Theme sáng
  static ThemeData get minimalistLight => _buildTheme(
        brightness: Brightness.light,
        scaffold: scaffoldBg,
        card: cardBg,
        border: borderColor,
        inputBorder: inputBorderColor,
        textMain: textPrimary,
        textSub: textSecondary,
        statusBarBrightness: Brightness.dark,
        indicatorAlpha: 0.1,
      );

  /// Theme tối
  static ThemeData get minimalistDark => _buildTheme(
        brightness: Brightness.dark,
        scaffold: darkScaffoldBg,
        card: darkCardBg,
        border: darkBorderColor,
        inputBorder: darkBorderColor,
        textMain: darkTextPrimary,
        textSub: darkTextSecondary,
        statusBarBrightness: Brightness.light,
        indicatorAlpha: 0.2,
      );

  // Để tương thích
  static ThemeData get light => minimalistLight;
  static ThemeData get dark => minimalistDark;

  /// Builder chung — chỉ nhận các giá trị khác nhau giữa Light/Dark.
  ///
  /// Tại sao extract thay vì viết 2 getter riêng:
  ///   - Giảm ~200 dòng duplicate
  ///   - Thêm component theme mới chỉ sửa 1 chỗ
  ///   - Đảm bảo Light/Dark luôn đồng bộ cấu trúc
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color card,
    required Color border,
    required Color inputBorder,
    required Color textMain,
    required Color textSub,
    required Brightness statusBarBrightness,
    required double indicatorAlpha,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = isLight
        ? ColorScheme.light(
            primary: primaryPastel,
            onPrimary: Colors.white,
            primaryContainer: primaryLight,
            onPrimaryContainer: textMain,
            secondary: primaryPastel,
            onSecondary: Colors.white,
            secondaryContainer: scaffold,
            onSecondaryContainer: textMain,
            surface: card,
            onSurface: textMain,
            onSurfaceVariant: textSub,
            surfaceContainerHighest: scaffold,
            outline: border,
            error: expenseRed,
            onError: Colors.white,
          )
        : ColorScheme.dark(
            primary: primaryPastel,
            onPrimary: Colors.white,
            primaryContainer: primaryLight,
            onPrimaryContainer: Colors.white,
            secondary: primaryPastel,
            onSecondary: Colors.white,
            secondaryContainer: scaffold,
            onSecondaryContainer: textMain,
            surface: card,
            onSurface: textMain,
            onSurfaceVariant: textSub,
            surfaceContainerHighest: scaffold,
            outline: border,
            error: expenseRed,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: card,
        foregroundColor: textMain,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarBrightness,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textMain,
          letterSpacing: -0.3,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Navigation Bar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryPastel.withValues(alpha: indicatorAlpha),
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
            borderRadius: BorderRadius.circular(8),
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1.0,
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputBorder),
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
}
