enum NomePlano { solo, oficina, rede }

enum StatusAssinatura { ativa, cancelada, suspensa, trialing }

enum CicloCobranca { mensal, anual }

extension NomePlanoExt on NomePlano {
  String get label => switch (this) {
        NomePlano.solo    => 'Solo',
        NomePlano.oficina => 'Oficina',
        NomePlano.rede    => 'Rede',
      };
}

extension StatusAssinaturaExt on StatusAssinatura {
  String get label => switch (this) {
        StatusAssinatura.ativa     => 'ASSINATURA ATIVA',
        StatusAssinatura.cancelada => 'CANCELADA',
        StatusAssinatura.suspensa  => 'SUSPENSA',
        StatusAssinatura.trialing  => 'PERÍODO DE TESTE',
      };
}

class UsoPlano {
  const UsoPlano({
    required this.osMes,
    required this.osMesMax,
    required this.usuarios,
    required this.usuariosMax,
    required this.unidades,
    required this.unidadesMax,
    required this.fotosGb,
    required this.fotosGbMax,
  });

  final int osMes;
  final int? osMesMax;       // null = ilimitado
  final int usuarios;
  final int? usuariosMax;    // null = ilimitado
  final int unidades;
  final int? unidadesMax;
  final double fotosGb;
  final double? fotosGbMax;  // null = ilimitado

  factory UsoPlano.fromJson(Map<String, dynamic> json) => UsoPlano(
        osMes:       json['osMes'] as int,
        osMesMax:    json['osMesMax'] as int?,
        usuarios:    json['usuarios'] as int,
        usuariosMax: json['usuariosMax'] as int?,
        unidades:    json['unidades'] as int,
        unidadesMax: json['unidadesMax'] as int?,
        fotosGb:     (json['fotosGb'] as num).toDouble(),
        fotosGbMax:  json['fotosGbMax'] != null ? (json['fotosGbMax'] as num).toDouble() : null,
      );
}

class Fatura {
  const Fatura({
    required this.id,
    required this.competencia,
    required this.emissao,
    required this.plano,
    required this.valor,
    required this.pago,
    this.notaUrl,
  });

  final int id;
  final String competencia; // ex: "Maio - 2026"
  final DateTime emissao;
  final String plano;
  final double valor;
  final bool pago;
  final String? notaUrl;

  factory Fatura.fromJson(Map<String, dynamic> json) => Fatura(
        id:          json['id'] as int,
        competencia: json['competencia'] as String,
        emissao:     DateTime.parse(json['emissao'] as String),
        plano:       json['plano'] as String,
        valor:       (json['valor'] as num).toDouble(),
        pago:        json['pago'] as bool,
        notaUrl:     json['notaUrl'] as String?,
      );
}

class AssinaturaDetalhes {
  const AssinaturaDetalhes({
    required this.plano,
    required this.status,
    required this.precoMensal,
    required this.ciclo,
    required this.proximaCobranca,
    required this.uso,
    required this.faturas,
  });

  final NomePlano plano;
  final StatusAssinatura status;
  final double precoMensal;
  final CicloCobranca ciclo;
  final DateTime proximaCobranca;
  final UsoPlano uso;
  final List<Fatura> faturas;

  factory AssinaturaDetalhes.fromJson(Map<String, dynamic> json) =>
      AssinaturaDetalhes(
        plano:          NomePlano.values.byName(json['plano'] as String),
        status:         StatusAssinatura.values.byName(json['status'] as String),
        precoMensal:    (json['precoMensal'] as num).toDouble(),
        ciclo:          CicloCobranca.values.byName(json['ciclo'] as String),
        proximaCobranca: DateTime.parse(json['proximaCobranca'] as String),
        uso:            UsoPlano.fromJson(json['uso'] as Map<String, dynamic>),
        faturas:        (json['faturas'] as List)
            .map((f) => Fatura.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
}
