class OrdemServico {
  const OrdemServico({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.veiculoId,
    required this.veiculoDescricao,
    this.veiculoPlaca,
    required this.status,
    this.formaPagamento,
    this.observacoes,
    required this.dataEntrada,
    this.previsaoEntrega,
    this.dataConclusao,
    required this.totalMecanicos,
    required this.totalServicos,
    required this.totalPecas,
    required this.total,
    this.euSouMecanico = false,
    this.mecanicoNomes = const [],
    this.primeiroServico,
  });

  final int id;
  final int clienteId;
  final String clienteNome;
  final int veiculoId;
  final String veiculoDescricao;
  final String? veiculoPlaca;
  final String? primeiroServico;
  final String status;
  final String? formaPagamento;
  final String? observacoes;
  final DateTime dataEntrada;
  final DateTime? previsaoEntrega;
  final DateTime? dataConclusao;
  final int totalMecanicos;
  final double totalServicos;
  final double totalPecas;
  final double total;
  final bool euSouMecanico;
  final List<String> mecanicoNomes;

  factory OrdemServico.fromJson(Map<String, dynamic> json) => OrdemServico(
        id: json['id'] as int,
        clienteId: json['clienteId'] as int,
        clienteNome: json['clienteNome'] as String,
        veiculoId: json['veiculoId'] as int,
        veiculoDescricao: json['veiculoDescricao'] as String,
        veiculoPlaca: json['veiculoPlaca'] as String?,
        status: json['status'] as String,
        formaPagamento: json['formaPagamento'] as String?,
        observacoes: json['observacoes'] as String?,
        dataEntrada: DateTime.parse(json['dataEntrada'] as String).toLocal(),
        previsaoEntrega: json['previsaoEntrega'] != null
            ? DateTime.parse(json['previsaoEntrega'] as String)
            : null,
        dataConclusao: json['dataConclusao'] != null
            ? DateTime.parse(json['dataConclusao'] as String)
            : null,
        totalMecanicos: json['totalMecanicos'] as int,
        totalServicos: (json['totalServicos'] as num).toDouble(),
        totalPecas: (json['totalPecas'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        euSouMecanico: json['euSouMecanico'] as bool? ?? false,
        mecanicoNomes: (json['mecanicoNomes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        primeiroServico: json['primeiroServico'] as String?,
      );
}
