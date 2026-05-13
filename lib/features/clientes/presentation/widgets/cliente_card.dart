import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../domain/veiculo_resumo.dart';
import 'contact_row.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({
    super.key,
    required this.nome,
    required this.desde,
    required this.telefone,
    required this.email,
    required this.cidade,
    this.veiculos = const [],
    this.onTap,
    this.onLongPress,
    this.onAddVeiculo,
    this.onEditVeiculo,
  });

  final String nome;
  final String desde;
  final String telefone;
  final String email;
  final String cidade;
  final List<VeiculoResumo> veiculos;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAddVeiculo;
  final void Function(VeiculoResumo)? onEditVeiculo;

  String get _initials {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

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
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Desde $desde',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ContactRow(icon: Icons.phone_outlined, value: telefone),
            ContactRow(icon: Icons.email_outlined, value: email),
            ContactRow(icon: Icons.location_on_outlined, value: cidade),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VEÍCULOS (${veiculos.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (onAddVeiculo != null)
                  GestureDetector(
                    onTap: onAddVeiculo,
                    child: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: veiculos.map((v) => _VeiculoChip(
                veiculo: v,
                onTap: onEditVeiculo != null ? () => onEditVeiculo!(v) : null,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VeiculoChip extends StatelessWidget {
  const _VeiculoChip({required this.veiculo, this.onTap});

  final VeiculoResumo veiculo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: onTap != null ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              veiculo.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onTap != null ? AppColors.primary : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 10, color: AppColors.primary.withValues(alpha: 0.7)),
            ],
          ],
        ),
      ),
    );
  }
}
