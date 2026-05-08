import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary       = Color(0xFF1565C0);
  static const primaryDark   = Color(0xFF0D47A1);
  static const primaryLight  = Color(0xFF42A5F5);
  static const primaryMid    = Color(0xFF1976D2);

  static const success       = Color(0xFF2E7D32);
  static const successLight  = Color(0xFFE8F5E9);
  static const warning       = Color(0xFFE65100);
  static const warningLight  = Color(0xFFFFF3E0);
  static const error         = Color(0xFFC62828);
  static const errorLight    = Color(0xFFFFEBEE);

  static const textPrimary   = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF757575);
  static const border        = Color(0xFFE0E0E0);
  static const surface       = Color(0xFFF5F7FA);
  static const sidebarBg    = Color(0xFFFFFFFF);
}

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.surface,
);
