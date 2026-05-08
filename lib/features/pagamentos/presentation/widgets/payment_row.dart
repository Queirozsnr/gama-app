import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../../../shared/widgets/chips/payment_badge.dart';

class PaymentRow extends StatelessWidget {
  const PaymentRow({
    super.key,
    required this.nome,
    required this.cargo,
    required this.paymentType,
    this.comissaoPercent,
    this.calculo,
    required this.valor,
  });

  final String nome;
  final String cargo;
  final PaymentType paymentType;
  final int? comissaoPercent;
  final String? calculo;
  final double valor;

  String get _initials {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GamaAvatar(initials: _initials, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  cargo,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PaymentBadge(type: paymentType, percent: comissaoPercent),
          const SizedBox(width: 8),
          if (calculo != null)
            Text(
              calculo!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            const Text('—', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(
            'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
