import 'package:flutter/material.dart';

class GamaAvatar extends StatelessWidget {
  const GamaAvatar({
    super.key,
    required this.initials,
    this.size = 40,
  });

  final String initials;
  final double size;

  static const _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF5B73E8), Color(0xFF8B5CF6)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFF10B981), Color(0xFF3B82F6)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFF6366F1), Color(0xFF06B6D4)],
    [Color(0xFF14B8A6), Color(0xFF6366F1)],
  ];

  List<Color> _gradientFor(String text) {
    final hash = text.codeUnits.fold(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(initials);
    final fontSize = size * 0.38;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
