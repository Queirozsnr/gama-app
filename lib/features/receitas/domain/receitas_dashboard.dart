class ReceitaDiaria {
  const ReceitaDiaria({required this.data, required this.valor});
  final DateTime data;
  final double valor;

  factory ReceitaDiaria.fromJson(Map<String, dynamic> json) => ReceitaDiaria(
        data: DateTime.parse(json['data'] as String),
        valor: (json['valor'] as num).toDouble(),
      );
}

class PagamentoRecente {
  const PagamentoRecente({
    required this.ordemServicoId,
    required this.clienteNome,
    this.formaPagamento,
    required this.valor,
    required this.dataHora,
  });
  final int ordemServicoId;
  final String clienteNome;
  final String? formaPagamento;
  final double valor;
  final DateTime dataHora;

  factory PagamentoRecente.fromJson(Map<String, dynamic> json) => PagamentoRecente(
        ordemServicoId: json['ordemServicoId'] as int,
        clienteNome: json['clienteNome'] as String,
        formaPagamento: json['formaPagamento'] as String?,
        valor: (json['valor'] as num).toDouble(),
        dataHora: DateTime.parse(json['dataHora'] as String),
      );
}

class ReceitaPorMecanico {
  const ReceitaPorMecanico({
    required this.funcionarioId,
    required this.nome,
    required this.totalOs,
    required this.ticketMedio,
    required this.receita,
    required this.progressPct,
    required this.tipoRemuneracao,
    this.porcentagem,
    required this.liquidoOwner,
    required this.liquidoOwnerProgressPct,
  });
  final int funcionarioId;
  final String nome;
  final int totalOs;
  final double ticketMedio;
  final double receita;
  final double progressPct;
  final String tipoRemuneracao;
  final int? porcentagem;
  final double liquidoOwner;
  final double liquidoOwnerProgressPct;

  factory ReceitaPorMecanico.fromJson(Map<String, dynamic> json) => ReceitaPorMecanico(
        funcionarioId: json['funcionarioId'] as int,
        nome: json['nome'] as String,
        totalOs: json['totalOs'] as int,
        ticketMedio: (json['ticketMedio'] as num).toDouble(),
        receita: (json['receita'] as num).toDouble(),
        progressPct: (json['progressPct'] as num).toDouble(),
        tipoRemuneracao: json['tipoRemuneracao'] as String,
        porcentagem: json['porcentagem'] as int?,
        liquidoOwner: (json['liquidoOwner'] as num).toDouble(),
        liquidoOwnerProgressPct: (json['liquidoOwnerProgressPct'] as num).toDouble(),
      );
}

class DespesasDetalhe {
  const DespesasDetalhe({
    required this.pecas,
    required this.folha,
    required this.fixos,
  });
  final double pecas;
  final double folha;
  final double fixos;

  factory DespesasDetalhe.fromJson(Map<String, dynamic> json) => DespesasDetalhe(
        pecas: (json['pecas'] as num).toDouble(),
        folha: (json['folha'] as num).toDouble(),
        fixos: (json['fixos'] as num).toDouble(),
      );
}

class ReceitasDashboard {
  const ReceitasDashboard({
    required this.receitaBruta,
    required this.despesas,
    required this.despesasDetalhe,
    required this.lucroLiquido,
    required this.ticketMedio,
    required this.totalOs,
    required this.receitaDiaria,
    required this.pagamentosRecentes,
    required this.receitaPorMecanico,
  });

  final double receitaBruta;
  final double despesas;
  final DespesasDetalhe despesasDetalhe;
  final double lucroLiquido;
  final double ticketMedio;
  final int totalOs;
  final List<ReceitaDiaria> receitaDiaria;
  final List<PagamentoRecente> pagamentosRecentes;
  final List<ReceitaPorMecanico> receitaPorMecanico;

  factory ReceitasDashboard.fromJson(Map<String, dynamic> json) => ReceitasDashboard(
        receitaBruta: (json['receitaBruta'] as num).toDouble(),
        despesas: (json['despesas'] as num).toDouble(),
        despesasDetalhe: DespesasDetalhe.fromJson(
            json['despesasDetalhe'] as Map<String, dynamic>),
        lucroLiquido: (json['lucroLiquido'] as num).toDouble(),
        ticketMedio: (json['ticketMedio'] as num).toDouble(),
        totalOs: json['totalOs'] as int,
        receitaDiaria: (json['receitaDiaria'] as List<dynamic>)
            .map((e) => ReceitaDiaria.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagamentosRecentes: (json['pagamentosRecentes'] as List<dynamic>)
            .map((e) => PagamentoRecente.fromJson(e as Map<String, dynamic>))
            .toList(),
        receitaPorMecanico: (json['receitaPorMecanico'] as List<dynamic>)
            .map((e) => ReceitaPorMecanico.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
