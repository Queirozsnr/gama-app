import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Garage palette ─────────────────────────────────────────
  static const bg          = Color(0xFFF4F0E6); // warm off-white page bg
  static const surface     = Color(0xFFFFFDF8); // card / panel surface
  static const surface2    = Color(0xFFF8F3E6); // secondary surface / input fill
  static const ink         = Color(0xFF1F1C17); // primary text
  static const ink2        = Color(0xFF75695A); // secondary text
  static const ink3        = Color(0xFFB1A695); // tertiary / placeholder
  static const line        = Color(0xFFE7E0D0); // default borders
  static const lineHard    = Color(0xFFD2C8B3); // stronger borders

  static const sidebarBg   = Color(0xFF1A1714); // dark sidebar bg
  static const sidebarLine = Color(0xFF2C2722); // sidebar dividers
  static const sidebarText = Color(0xFFBDB2A1); // sidebar muted text

  static const accent      = Color(0xFFFF7A1A); // amber accent / primary CTA
  static const accentDark  = Color(0xFFCC5A00); // darker amber hover
  static const accentSoft  = Color(0xFFFFE9D0); // light amber fill / tint

  static const ok          = Color(0xFF1F8A52); // success green
  static const okSoft      = Color(0xFFE0F1E6); // light success fill
  static const warn        = Color(0xFFC28012); // warning amber-brown
  static const warnSoft    = Color(0xFFFBEED1); // light warning fill
  static const danger      = Color(0xFFB83524); // danger red
  static const dangerSoft  = Color(0xFFFBE1DA); // light danger fill
  static const info        = Color(0xFF1D7FC4); // info blue (in-progress, fixed salary)
  static const infoSoft    = Color(0xFFE0F0FB); // light info fill

  // ── Backward-compat aliases ────────────────────────────────
  static const primary      = accent;
  static const primaryDark  = accentDark;
  static const primaryLight = Color(0xFFFFAB6E);
  static const primaryMid   = accent;

  static const success      = ok;
  static const successLight = okSoft;
  static const warning      = warn;
  static const warningLight = warnSoft;
  static const error        = danger;
  static const errorLight   = dangerSoft;

  static const textPrimary   = ink;
  static const textSecondary = ink2;
  static const border        = line;
  static const surface0      = bg;
}

const _inter = 'Inter';

TextStyle _i({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: _inter,
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  letterSpacing: letterSpacing,
);

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Color(0xFF1A1714),
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: Color(0xFF1A1714),
    secondary: AppColors.ink2,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surface2,
    onSecondaryContainer: AppColors.ink,
    tertiary: AppColors.ok,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.okSoft,
    onTertiaryContainer: AppColors.ok,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.surface2,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.danger,
    outline: AppColors.line,
    outlineVariant: AppColors.lineHard,
  ),
  textTheme: TextTheme(
    bodyLarge:       _i(fontSize: 15, color: AppColors.ink),
    bodyMedium:      _i(fontSize: 13, color: AppColors.ink),
    bodySmall:       _i(fontSize: 11, color: AppColors.ink2),
    labelLarge:      _i(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
    titleMedium:     _i(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
    titleLarge:      _i(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.3),
    headlineSmall:   _i(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5),
    headlineMedium:  _i(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.6),
    // defaults
    displayLarge:    _i(color: AppColors.ink),
    displayMedium:   _i(color: AppColors.ink),
    displaySmall:    _i(color: AppColors.ink),
    headlineLarge:   _i(color: AppColors.ink),
    titleSmall:      _i(color: AppColors.ink),
    labelMedium:     _i(color: AppColors.ink),
    labelSmall:      _i(color: AppColors.ink),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.line),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: _i(fontSize: 13, color: AppColors.ink2),
    hintStyle:  _i(fontSize: 13, color: AppColors.ink3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: const Color(0xFF1A1714),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: _i(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.line),
      foregroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: _i(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.accent,
      textStyle: _i(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.line,
    thickness: 1,
    space: 1,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surface2,
    side: const BorderSide(color: AppColors.line),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    labelStyle: _i(fontSize: 12, color: AppColors.ink),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 8,
    shadowColor: Colors.black26,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    elevation: 8,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.ink,
    contentTextStyle: _i(color: Colors.white, fontSize: 13),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior: SnackBarBehavior.floating,
  ),
  iconTheme: const IconThemeData(color: AppColors.ink2, size: 20),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.ink,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: _i(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.line),
    ),
    elevation: 8,
  ),
);
