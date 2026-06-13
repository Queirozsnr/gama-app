class OsResumo {
  const OsResumo({
    required this.totalOs,
    required this.abertas,
    required this.emAndamento,
    required this.aguardandoPeca,
    required this.valorTotal,
    required this.osNoMes,
    this.limiteOsPorMes,
  });

  final int totalOs;
  final int abertas;
  final int emAndamento;
  final int aguardandoPeca;
  final double valorTotal;
  final int osNoMes;
  final int? limiteOsPorMes;

  bool get limiteAtingido =>
      limiteOsPorMes != null && osNoMes >= limiteOsPorMes!;

  bool get limiteProximo =>
      limiteOsPorMes != null && osNoMes >= (limiteOsPorMes! * 0.8).ceil();

  factory OsResumo.fromJson(Map<String, dynamic> json) => OsResumo(
        totalOs:        (json['totalOs'] as num).toInt(),
        abertas:        (json['abertas'] as num).toInt(),
        emAndamento:    (json['emAndamento'] as num).toInt(),
        aguardandoPeca: (json['aguardandoPeca'] as num).toInt(),
        valorTotal:     (json['valorTotal'] as num).toDouble(),
        osNoMes:        (json['osNoMes'] as num).toInt(),
        limiteOsPorMes: json['limiteOsPorMes'] as int?,
      );
}
