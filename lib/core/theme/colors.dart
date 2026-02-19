import 'package:flutter/material.dart';

/// 爆款视觉 + IsThereAnyDeal 风格：折扣橙、清晰层级
class AppColors {
  AppColors._();

  static const Color bgDark = Color(0xFF0B141B);
  static const Color cardDark = Color(0xFF1A2332);
  static const Color neonGreen = Color(0xFF1AFF8C);
  static const Color neonPurple = Color(0xFF8A5CFF);
  static const Color discountRed = Color(0xFFFF4C4C);
  /// IsThereAnyDeal 风格：折扣徽章主色（-78% 那种橙）
  static const Color itadOrange = Color(0xFFE85D04);
  static const Color itadOrangeLight = Color(0xFFFF7B2C);

  /// 主色：与折扣/按钮统一的 ITAD 橙（原 neonGreen 已不再作为主色）
  static const Color primary = itadOrange;
  static const Color accent = Color(0xFF00BFFF);
  static const Color danger = Color(0xFFFF3B30);
  static const Color gold = Color(0xFFFFD700);

  static const Color background = bgDark;
  static const Color surface = cardDark;
  static const Color card = cardDark;
  static const Color cardElevated = Color(0xFF1E3A4D);

  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF9AA0A6);

  static const Color successGreen = Color(0xFF34D399);
  static const Color backgroundDark = bgDark;
  static const Color heatOrange = Color(0xFFFF9500);
  static const Color newBlue = Color(0xFF00BFFF);
}
