import 'package:flutter/material.dart';

class StockQtyBadge extends StatelessWidget {
  const StockQtyBadge({super.key, required this.qty, required this.min});

  final int qty;
  final int min;

  bool get _isCritical => qty < min;

  @override
  Widget build(BuildContext context) {
    final color = _isCritical ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bgColor = _isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$qty/$min',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
