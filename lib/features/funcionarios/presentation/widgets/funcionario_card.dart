import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../../../shared/widgets/chips/payment_badge.dart';

class FuncionarioCard extends StatelessWidget {
  const FuncionarioCard({
    super.key,
    required this.nome,
    required this.cargo,
    required this.paymentType,
    this.comissaoPercent,
    required this.osNoMes,
    required this.valor,
    this.onTap,
  });

  final String nome;
  final String cargo;
  final PaymentType paymentType;
  final int? comissaoPercent;
  final int osNoMes;
  final double valor;
  final VoidCallback? onTap;

  String get _initials {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  String get _valorLabel => paymentType == PaymentType.fixo ? 'Salário' : 'A pagar';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GamaAvatar(initials: _initials, size: 44),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      cargo,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    PaymentBadge(type: paymentType, percent: comissaoPercent),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OS no mês',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.build_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$osNoMes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _valorLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
