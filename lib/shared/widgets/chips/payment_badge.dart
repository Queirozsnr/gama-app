import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum PaymentType { comissao, fixo, socio }

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
        PaymentType.socio    => 'Gerente',
      };

  Color get _bgColor => switch (type) {
        PaymentType.comissao => AppColors.accentSoft,
        PaymentType.fixo     => AppColors.infoSoft,
        PaymentType.socio    => AppColors.warnSoft,
      };

  Color get _textColor => switch (type) {
        PaymentType.comissao => AppColors.accentDark,
        PaymentType.fixo     => AppColors.info,
        PaymentType.socio    => AppColors.warn,
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
