import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../../../shared/widgets/chips/payment_badge.dart';
import '../../domain/funcionario.dart';

const _cargoLabels = {
  'Gerente': 'Gerente',
  'Mecanico': 'Mecânico',
  'Auxiliar': 'Auxiliar',
  'Atendente': 'Atendente',
  'Lavador': 'Lavador',
  'Funileiro': 'Funileiro',
  'Eletricista': 'Eletricista',
  'Pintor': 'Pintor',
  'TecnicoArCondicionado': 'Técnico AC',
};

class FuncionarioCard extends StatelessWidget {
  const FuncionarioCard({
    super.key,
    required this.funcionario,
    this.onTap,
    this.onLongPress,
    this.onResetarSenha,
  });

  final Funcionario funcionario;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onResetarSenha;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  PaymentType get _paymentType =>
      funcionario.tipoRemuneracao == 'Fixo' ? PaymentType.fixo : PaymentType.comissao;

  int? get _comissaoPercent =>
      funcionario.porcentagem != null ? funcionario.porcentagem!.toInt() : null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        funcionario.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        _cargoLabels[funcionario.cargo] ?? funcionario.cargo,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      PaymentBadge(type: _paymentType, percent: _comissaoPercent),
                    ],
                  ),
                ),
                if (onResetarSenha != null)
                  IconButton(
                    onPressed: onResetarSenha,
                    icon: const Icon(Icons.lock_reset_outlined),
                    color: AppColors.textSecondary,
                    tooltip: 'Resetar senha',
                  ),
              ],
            ),
            if (funcionario.oficinas.isNotEmpty) ...[
              const Divider(height: 20),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: funcionario.oficinas.map((o) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(o.nome, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
