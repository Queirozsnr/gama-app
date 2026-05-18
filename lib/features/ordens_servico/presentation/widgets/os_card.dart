import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final prazoLabel = _prazoLabel(os.previsaoEntrega);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: atrasada
                ? AppColors.danger.withValues(alpha: 0.45)
                : AppColors.line,
            width: atrasada ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: #id · status badge · prazo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '#${os.id}',
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(width: 8),
                _DotStatus(status: status),
                const Spacer(),
                if (prazoLabel.isNotEmpty)
                  Text(
                    prazoLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: atrasada ? AppColors.danger : AppColors.ink3,
                    ),
                  ),
              ],
            ),
            // Row 2: title
            if (os.primeiroServico != null) ...[
              const SizedBox(height: 6),
              Text(
                os.primeiroServico!,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            // Row 3: plate + vehicle · client
            Row(
              children: [
                if (os.veiculoPlaca != null) ...[
                  _PlateTag(os.veiculoPlaca!),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    '${os.veiculoDescricao} · ${os.clienteNome}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.ink2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 4: mechanic avatar + name · value
            Row(
              children: [
                if (os.mecanicoNomes.isNotEmpty) ...[
                  _MiniAvatar(nome: os.mecanicoNomes.first),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      os.mecanicoNomes.length == 1
                          ? os.mecanicoNomes.first
                          : '${os.mecanicoNomes.first} +${os.mecanicoNomes.length - 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                Text(
                  _fmtBrl(os.total),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _prazoLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'HOJE $h:$m';
    }
    if (diff == 1) return 'AMANHÃ';
    if (diff == -1) return 'ONTEM';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  static String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _DotStatus extends StatelessWidget {
  const _DotStatus({required this.status});
  final OsStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: status.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: status.textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _PlateTag extends StatelessWidget {
  const _PlateTag(this.plate);
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

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    final initials = nome
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}
