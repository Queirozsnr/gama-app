import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/chips/status_chip.dart';
import '../../domain/ordem_servico.dart';

class OsCard extends StatelessWidget {
  const OsCard({super.key, required this.os, this.onTap, this.onLongPress});

  final OrdemServico os;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final status = OsStatus.fromString(os.status);
    final atrasada = os.previsaoEntrega != null &&
        DateTime.now().isAfter(os.previsaoEntrega!) &&
        os.status != 'Concluida' &&
        os.status != 'Entregue';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: atrasada
              ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5)
              : null,
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
            // Barra de status colorida
            if (status.accentColor != Colors.transparent)
              Container(height: 3, color: status.accentColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'OS #${os.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Cliente
                  _Row(Icons.person_outline, os.clienteNome, bold: true),
                  const SizedBox(height: 3),
                  // Veículo
                  _Row(
                    Icons.directions_car_outlined,
                    os.veiculoPlaca != null
                        ? '${os.veiculoDescricao} · ${os.veiculoPlaca}'
                        : os.veiculoDescricao,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(_fmt(os.dataEntrada),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const Spacer(),
                      if (os.totalMecanicos > 0) ...[
                        const Icon(Icons.engineering_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('${os.totalMecanicos}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'R\$ ${os.total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (atrasada) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined, size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Previsão: ${_fmt(os.previsaoEntrega!)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.text, {this.bold = false});
  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
