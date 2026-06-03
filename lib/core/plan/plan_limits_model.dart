class PlanLimits {
  const PlanLimits({
    this.maxOficinas,
    this.maxUsuariosPorOficina,
    this.maxOsPorMes,
    this.maxItensEstoque,
    this.maxClientesVeiculos,
    required this.estoqueCompleto,
    required this.relatoriosFinanceiros,
    required this.pagamentoFuncionarios,
    required this.fotosVideosOS,
    required this.multiOficina,
    required this.personalizacaoBasica,
    required this.personalizacaoCompleta,
    required this.importacaoDados,
    required this.auditLog,
  });

  final int? maxOficinas;
  final int? maxUsuariosPorOficina;
  final int? maxOsPorMes;
  final int? maxItensEstoque;
  final int? maxClientesVeiculos;
  final bool estoqueCompleto;
  final bool relatoriosFinanceiros;
  final bool pagamentoFuncionarios;
  final bool fotosVideosOS;
  final bool multiOficina;
  final bool personalizacaoBasica;
  final bool personalizacaoCompleta;
  final bool importacaoDados;
  final bool auditLog;

  factory PlanLimits.fromJson(Map<String, dynamic> json) => PlanLimits(
        maxOficinas: json['maxOficinas'] as int?,
        maxUsuariosPorOficina: json['maxUsuariosPorOficina'] as int?,
        maxOsPorMes: json['maxOsPorMes'] as int?,
        maxItensEstoque: json['maxItensEstoque'] as int?,
        maxClientesVeiculos: json['maxClientesVeiculos'] as int?,
        estoqueCompleto: json['estoqueCompleto'] as bool,
        relatoriosFinanceiros: json['relatoriosFinanceiros'] as bool,
        pagamentoFuncionarios: json['pagamentoFuncionarios'] as bool,
        fotosVideosOS: json['fotosVideosOS'] as bool,
        multiOficina: json['multiOficina'] as bool,
        personalizacaoBasica: json['personalizacaoBasica'] as bool,
        personalizacaoCompleta: json['personalizacaoCompleta'] as bool,
        importacaoDados: json['importacaoDados'] as bool,
        auditLog: json['auditLog'] as bool,
      );

  bool get limiteOficinas => maxOficinas != null;
  bool get limiteUsuarios => maxUsuariosPorOficina != null;
  bool get limiteOS => maxOsPorMes != null;
  bool get limiteEstoque => maxItensEstoque != null;
  bool get limiteClientesVeiculos => maxClientesVeiculos != null;
}
