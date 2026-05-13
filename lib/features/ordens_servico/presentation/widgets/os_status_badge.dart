import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class OsStatusBadge extends StatelessWidget {
  const OsStatusBadge(this.status, {super.key, this.small = false});

  final String status;
  final bool small;

  static const _cfg = {
    'Aberta':           ('Aberta',            AppColors.primary,    Color(0xFFE3F0FF)),
    'EmAndamento':      ('Em andamento',       AppColors.warning,    Color(0xFFFFF3E0)),
    'AguardandoPecas':  ('Aguardando peças',   Color(0xFFF57F17),   Color(0xFFFFFDE7)),
    'Concluida':        ('Concluída',          AppColors.success,    AppColors.successLight),
    'Entregue':         ('Entregue',           AppColors.textSecondary, Color(0xFFF5F5F5)),
  };

  static String label(String status) => _cfg[status]?.$1 ?? status;
  static Color textColor(String status) => _cfg[status]?.$2 ?? AppColors.textSecondary;
  static Color bgColor(String status) => _cfg[status]?.$3 ?? AppColors.surface;

  @override
  Widget build(BuildContext context) {
    final (lbl, fg, bg) = _cfg[status] ?? (status, AppColors.textSecondary, AppColors.surface);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        lbl,
        style: TextStyle(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
