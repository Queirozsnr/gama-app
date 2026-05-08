import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gama_avatar.dart';
import '../../../../shared/widgets/chips/vehicle_plate_chip.dart';
import 'contact_row.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({
    super.key,
    required this.nome,
    required this.desde,
    required this.telefone,
    required this.email,
    required this.cidade,
    required this.placas,
    this.onTap,
  });

  final String nome;
  final String desde;
  final String telefone;
  final String email;
  final String cidade;
  final List<String> placas;
  final VoidCallback? onTap;

  String get _initials {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

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
                      'Desde $desde',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ContactRow(icon: Icons.phone_outlined, value: telefone),
            ContactRow(icon: Icons.email_outlined, value: email),
            ContactRow(icon: Icons.location_on_outlined, value: cidade),
            const Divider(height: 20),
            Text(
              'VEÍCULOS (${placas.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: placas.map((p) => VehiclePlateChip(plate: p)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
