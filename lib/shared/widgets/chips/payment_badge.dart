import 'package:flutter/material.dart';

enum PaymentType { comissao, fixo }

class PaymentBadge extends StatelessWidget {
  const PaymentBadge({
    super.key,
    required this.type,
    this.percent,
  });

  final PaymentType type;
  final int? percent;

  String get _label => switch (type) {
        PaymentType.comissao => percent != null ? '$percent% comissão' : 'Comissão',
        PaymentType.fixo     => 'Fixo mensal',
      };

  Color get _bgColor => switch (type) {
        PaymentType.comissao => const Color(0xFFFFF3E0),
        PaymentType.fixo     => const Color(0xFFE3F2FD),
      };

  Color get _textColor => switch (type) {
        PaymentType.comissao => const Color(0xFFE65100),
        PaymentType.fixo     => const Color(0xFF1565C0),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
      ),
    );
  }
}
