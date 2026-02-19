import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 应用主题 - Material 3 + Montserrat，商业版
class AppTheme {
  static const Color _primary = Color(0xFF171A21);
  static const Color _primaryVariant = Color(0xFF2D3748);
  static const Color _surface = Color(0xFF0F1115);
  static const Color _surfaceCard = Color(0xFF252A33);
  static const Color _accent = Color(0xFF66C0F4);
  static const Color _accentVariant = Color(0xFF4A9FD4);
  static const Color _discountRed = Color(0xFFC54534);
  static const Color _successGreen = Color(0xFF5C7E10);
  static const Color _textPrimary = Color(0xFFE8EAED);
  static const Color _textSecondary = Color(0xFF9AA0A6);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _accent,
      secondary: _accent,
      surface: _surface,
      error: _discountRed,
      onPrimary: _textPrimary,
      onSurface: _textPrimary,
      onError: _textPrimary,
    ),
    scaffoldBackgroundColor: _surface,
    cardTheme: CardThemeData(
      color: _surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: _textPrimary, size: 24),
      titleTextStyle: GoogleFonts.montserrat(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: GoogleFonts.montserratTextTheme(
      const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: _textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: _textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: _textSecondary),
      ),
    ),
    dividerColor: _textSecondary.withOpacity(0.3),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceCard,
      hintStyle: const TextStyle(color: _textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
