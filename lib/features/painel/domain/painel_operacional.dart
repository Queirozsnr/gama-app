class OsResumo {
  const OsResumo({
    required this.id,
    required this.servico,
    required this.clienteNome,
    this.placa,
    this.veiculoDescricao,
    required this.status,
    required this.valor,
    this.previsaoEntrega,
  });

  final int id;
  final String servico;
  final String clienteNome;
  final String? placa;
  final String? veiculoDescricao;
  final String status;
  final double valor;
  final DateTime? previsaoEntrega;

  factory OsResumo.fromJson(Map<String, dynamic> json) => OsResumo(
        id: (json['id'] as num).toInt(),
        servico: json['servico'] as String,
        clienteNome: json['clienteNome'] as String,
        placa: json['placa'] as String?,
        veiculoDescricao: json['veiculoDescricao'] as String?,
        status: json['status'] as String,
        valor: (json['valor'] as num).toDouble(),
        previsaoEntrega: json['previsaoEntrega'] != null
            ? DateTime.parse(json['previsaoEntrega'] as String)
            : null,
      );
}

class MembroEquipe {
  const MembroEquipe({
    required this.funcionarioId,
    required this.nome,
    required this.cargoLabel,
    required this.osHoje,
    required this.ativo,
  });

  final int funcionarioId;
  final String nome;
  final String cargoLabel;
  final int osHoje;
  final bool ativo;

  factory MembroEquipe.fromJson(Map<String, dynamic> json) => MembroEquipe(
        funcionarioId: (json['funcionarioId'] as num).toInt(),
        nome: json['nome'] as String,
        cargoLabel: json['cargoLabel'] as String,
        osHoje: json['osHoje'] as int,
        ativo: json['ativo'] as bool,
      );
}

class ProdutoCritico {
  const ProdutoCritico({
    required this.nome,
    required this.codigo,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
  });

  final String nome;
  final String codigo;
  final double quantidadeAtual;
  final double quantidadeMinima;

  factory ProdutoCritico.fromJson(Map<String, dynamic> json) => ProdutoCritico(
        nome: json['nome'] as String,
        codigo: json['codigo'] as String,
        quantidadeAtual: (json['quantidadeAtual'] as num).toDouble(),
        quantidadeMinima: (json['quantidadeMinima'] as num).toDouble(),
      );
}

class PainelOperacional {
  const PainelOperacional({
    required this.osAbertas,
    required this.osAbertasDelta,
    required this.faturamentoMes,
    required this.faturamentoMesDeltaPct,
    required this.emAprovacao,
    required this.emAprovacaoDelta,
    required this.ticketMedio,
    required this.ticketMedioDelta,
    required this.osEmAndamento,
    required this.equipe,
    required this.produtosCriticos,
  });

  final int osAbertas;
  final int osAbertasDelta;
  final double faturamentoMes;
  final double faturamentoMesDeltaPct;
  final int emAprovacao;
  final int emAprovacaoDelta;
  final double ticketMedio;
  final double ticketMedioDelta;
  final List<OsResumo> osEmAndamento;
  final List<MembroEquipe> equipe;
  final List<ProdutoCritico> produtosCriticos;

  factory PainelOperacional.fromJson(Map<String, dynamic> json) =>
      PainelOperacional(
        osAbertas: json['osAbertas'] as int,
        osAbertasDelta: json['osAbertasDelta'] as int,
        faturamentoMes: (json['faturamentoMes'] as num).toDouble(),
        faturamentoMesDeltaPct:
            (json['faturamentoMesDeltaPct'] as num).toDouble(),
        emAprovacao: json['emAprovacao'] as int,
        emAprovacaoDelta: json['emAprovacaoDelta'] as int,
        ticketMedio: (json['ticketMedio'] as num).toDouble(),
        ticketMedioDelta: (json['ticketMedioDelta'] as num).toDouble(),
        osEmAndamento: (json['osEmAndamento'] as List<dynamic>)
            .map((e) => OsResumo.fromJson(e as Map<String, dynamic>))
            .toList(),
        equipe: (json['equipe'] as List<dynamic>)
            .map((e) => MembroEquipe.fromJson(e as Map<String, dynamic>))
            .toList(),
        produtosCriticos: (json['produtosCriticos'] as List<dynamic>)
            .map((e) => ProdutoCritico.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
