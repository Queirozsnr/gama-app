import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum GamaButtonVariant { primary, secondary }

class GamaButton extends StatelessWidget {
  const GamaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.variant = GamaButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final GamaButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    final Widget button = switch (variant) {
      GamaButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: child,
        ),
      GamaButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: child,
        ),
    };

    if (isFullWidth) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}
