import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/chips/status_chip.dart';
import '../../../../shared/widgets/gama_avatar.dart';

class OsCard extends StatelessWidget {
  const OsCard({
    super.key,
    required this.numero,
    required this.status,
    required this.abertura,
    required this.veiculoNome,
    required this.veiculoInfo,
    required this.descricao,
    required this.responsavelNome,
    required this.responsavelIniciais,
    required this.valor,
    this.onTap,
  });

  final String numero;
  final OsStatus status;
  final String abertura;
  final String veiculoNome;
  final String veiculoInfo;
  final String descricao;
  final String responsavelNome;
  final String responsavelIniciais;
  final double valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = status.accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accent != Colors.transparent)
              Container(height: 4, color: accent),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        numero,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    abertura,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    veiculoNome,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    veiculoInfo,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    descricao,
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GamaAvatar(initials: responsavelIniciais, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          responsavelNome,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
