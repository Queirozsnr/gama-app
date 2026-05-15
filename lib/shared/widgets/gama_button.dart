import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum GamaButtonVariant { primary, secondary, danger }

class GamaButton extends StatelessWidget {
  const GamaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = GamaButtonVariant.primary,
    this.icon,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final GamaButtonVariant variant;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == GamaButtonVariant.primary
                  ? const Color(0xFF1A1714)
                  : AppColors.accent,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final labelStyle = GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5);

    Widget button = switch (variant) {
      GamaButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: const Color(0xFF1A1714),
            disabledBackgroundColor: AppColors.accentSoft,
            disabledForegroundColor: AppColors.accentDark,
            shape: shape,
            minimumSize: Size(0, height),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            textStyle: labelStyle,
          ),
          child: child,
        ),
      GamaButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.line),
            foregroundColor: AppColors.ink,
            shape: shape,
            minimumSize: Size(0, height),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: labelStyle,
          ),
          child: child,
        ),
      GamaButtonVariant.danger => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: shape,
            minimumSize: Size(0, height),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            textStyle: labelStyle,
          ),
          child: child,
        ),
    };

    if (isFullWidth) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}
