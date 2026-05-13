import 'package:flutter/material.dart';

enum OsStatus { aberta, emAndamento, aguardandoPeca, concluida, entregue;

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
        OsStatus.aberta         => 'Aberta',
        OsStatus.emAndamento    => 'Em andamento',
        OsStatus.aguardandoPeca => 'Aguardando peça',
        OsStatus.concluida      => 'Concluída',
        OsStatus.entregue       => 'Entregue',
      };

  Color get dotColor => switch (this) {
        OsStatus.aberta         => const Color(0xFF9E9E9E),
        OsStatus.emAndamento    => const Color(0xFF1565C0),
        OsStatus.aguardandoPeca => const Color(0xFFE65100),
        OsStatus.concluida      => const Color(0xFF2E7D32),
        OsStatus.entregue       => const Color(0xFF546E7A),
      };

  Color get bgColor => switch (this) {
        OsStatus.aberta         => const Color(0xFFF5F5F5),
        OsStatus.emAndamento    => const Color(0xFFE3F2FD),
        OsStatus.aguardandoPeca => const Color(0xFFFFF3E0),
        OsStatus.concluida      => const Color(0xFFE8F5E9),
        OsStatus.entregue       => const Color(0xFFECEFF1),
      };

  Color get textColor => switch (this) {
        OsStatus.aberta         => const Color(0xFF757575),
        OsStatus.emAndamento    => const Color(0xFF1565C0),
        OsStatus.aguardandoPeca => const Color(0xFFE65100),
        OsStatus.concluida      => const Color(0xFF2E7D32),
        OsStatus.entregue       => const Color(0xFF546E7A),
      };

  Color get accentColor => switch (this) {
        OsStatus.aberta         => const Color(0xFF9E9E9E),
        OsStatus.emAndamento    => const Color(0xFF1565C0),
        OsStatus.aguardandoPeca => const Color(0xFFE65100),
        OsStatus.concluida      => const Color(0xFF2E7D32),
        OsStatus.entregue       => const Color(0xFF546E7A),
      };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final OsStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
