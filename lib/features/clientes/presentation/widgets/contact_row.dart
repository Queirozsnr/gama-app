import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
