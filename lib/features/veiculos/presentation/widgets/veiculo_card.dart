import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/chips/plate_badge.dart';

class VeiculoCard extends StatelessWidget {
  const VeiculoCard({
    super.key,
    required this.placa,
    required this.nome,
    required this.ano,
    required this.cor,
    required this.corHex,
    required this.km,
    required this.visitas,
    required this.proprietario,
    this.onTap,
  });

  final String placa;
  final String nome;
  final String ano;
  final String cor;
  final Color corHex;
  final String km;
  final int visitas;
  final String proprietario;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            Stack(
              children: [
                Container(height: 100, color: corHex),
                Positioned(
                  top: 10,
                  right: 10,
                  child: PlateBadge(plate: placa),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
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
                    '$ano • $cor',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.speed_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$km km',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '$visitas ${visitas == 1 ? 'visita' : 'visitas'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  const Text(
                    'Proprietário',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    proprietario,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
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
