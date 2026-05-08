import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VehiclePlateChip extends StatelessWidget {
  const VehiclePlateChip({super.key, required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car_outlined, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            plate,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
