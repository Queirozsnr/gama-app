import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CriticalStockTile extends StatelessWidget {
  const CriticalStockTile({
    super.key,
    required this.nome,
    required this.codigo,
    required this.qty,
    required this.min,
  });

  final String nome;
  final String codigo;
  final int qty;
  final int min;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  codigo,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$qty/$min',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
