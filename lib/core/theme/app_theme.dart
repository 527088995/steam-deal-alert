import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// 字体分级：H1 24 bold / H2 18 semiBold / Body 15 regular / Caption 13
/// 卡片：borderRadius 20, elevation 6, padding 16, 模块间距 24
class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Color(0xFF0B141B),
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 24),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      titleTextStyle: GoogleFonts.montserrat(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: GoogleFonts.montserratTextTheme(
      const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dividerColor: AppColors.textSecondary.withOpacity(0.2),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
