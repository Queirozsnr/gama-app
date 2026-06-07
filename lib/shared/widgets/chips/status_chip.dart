import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum OsStatus {
  aberta, emAndamento, aguardandoPeca, concluida, entregue;

  static OsStatus fromString(String s) => switch (s) {
    'Aberta'          => aberta,
    'EmAndamento'     => emAndamento,
    'AguardandoPecas' => aguardandoPeca,
    'Concluida'       => concluida,
    'Entregue'        => entregue,
    _                 => aberta,
  };
}

extension OsStatusX on OsStatus {
  String get label => switch (this) {
    OsStatus.aberta         => 'ABERTA',
    OsStatus.emAndamento    => 'EM ANDAMENTO',
    OsStatus.aguardandoPeca => 'AGUARDA PEÇA',
    OsStatus.concluida      => 'PRONTO',
    OsStatus.entregue       => 'ENTREGUE',
  };

  Color get dotColor => switch (this) {
    OsStatus.aberta         => AppColors.ink3,
    OsStatus.emAndamento    => AppColors.accent,
    OsStatus.aguardandoPeca => AppColors.warn,
    OsStatus.concluida      => AppColors.ok,
    OsStatus.entregue       => AppColors.info,
  };

  Color get bgColor => switch (this) {
    OsStatus.aberta         => AppColors.surface2,
    OsStatus.emAndamento    => AppColors.accentSoft,
    OsStatus.aguardandoPeca => AppColors.warnSoft,
    OsStatus.concluida      => AppColors.okSoft,
    OsStatus.entregue       => AppColors.infoSoft,
  };

  Color get textColor => switch (this) {
    OsStatus.aberta         => AppColors.ink2,
    OsStatus.emAndamento    => AppColors.accent,
    OsStatus.aguardandoPeca => AppColors.warn,
    OsStatus.concluida      => AppColors.ok,
    OsStatus.entregue       => AppColors.info,
  };

  Color get accentColor => switch (this) {
    OsStatus.aberta         => AppColors.ink3,
    OsStatus.emAndamento    => AppColors.accent,
    OsStatus.aguardandoPeca => AppColors.warn,
    OsStatus.concluida      => AppColors.ok,
    OsStatus.entregue       => AppColors.info,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.expand = false});

  final OsStatus status;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: status.textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
