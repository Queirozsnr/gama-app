import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum GamaSnackType { error, success, info }

abstract final class GamaSnackBar {
  static void show(
    BuildContext context,
    String message, {
    GamaSnackType type = GamaSnackType.error,
  }) {
    final (bg, icon) = switch (type) {
      GamaSnackType.error   => (AppColors.error,   Icons.error_outline_rounded),
      GamaSnackType.success => (AppColors.success, Icons.check_circle_outline_rounded),
      GamaSnackType.info    => (AppColors.primary,  Icons.info_outline_rounded),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void error(BuildContext context, String message) =>
      show(context, message, type: GamaSnackType.error);

  static void success(BuildContext context, String message) =>
      show(context, message, type: GamaSnackType.success);

  static void info(BuildContext context, String message) =>
      show(context, message, type: GamaSnackType.info);
}
