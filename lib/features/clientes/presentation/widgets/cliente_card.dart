import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../domain/cliente.dart';
import '../../domain/veiculo_resumo.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({
    super.key,
    required this.cliente,
    this.onTap,
    this.onLongPress,
    this.onAddVeiculo,
    this.onEditVeiculo,
  });

  final Cliente cliente;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAddVeiculo;
  final void Function(VeiculoResumo)? onEditVeiculo;

  String get _initials {
    final parts = cliente.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return cliente.nome.substring(0, cliente.nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final veiculos = cliente.veiculos;
    final telefone = cliente.telefone;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  GamaAvatar(initials: _initials, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (telefone != null && telefone.isNotEmpty)
                          Text(
                            telefone,
                            style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 12,
                              color: AppColors.ink2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (telefone != null && telefone.isNotEmpty)
                    _WhatsAppButton(telefone: telefone),
                ],
              ),
            ),
            if (veiculos.isNotEmpty) ...[
              Divider(height: 1, color: AppColors.line),
              _VeiculoRow(
                veiculo: veiculos.first,
                count: veiculos.length,
                onTap: onEditVeiculo != null ? () => onEditVeiculo!(veiculos.first) : onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.telefone});
  final String telefone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        size: 17,
        color: Color(0xFF25D366),
      ),
    );
  }
}

class _VeiculoRow extends StatelessWidget {
  const _VeiculoRow({required this.veiculo, required this.count, this.onTap});
  final VeiculoResumo veiculo;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
        child: Row(
          children: [
            if (veiculo.placa != null) ...[
              _PlateChip(veiculo.placa!),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                count > 1 ? '${veiculo.modeloNome} +${count - 1}' : veiculo.modeloNome,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 12,
                  color: AppColors.ink2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip(this.plate);
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        plate,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}
