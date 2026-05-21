class PerformanceOficina {
  const PerformanceOficina({
    required this.oficinaId,
    required this.nome,
    required this.receita,
    required this.totalOs,
    required this.ticketMedio,
    required this.totalMecanicos,
    required this.statusLabel,
  });

  final int oficinaId;
  final String nome;
  final double receita;
  final int totalOs;
  final double ticketMedio;
  final int totalMecanicos;
  final String statusLabel;

  factory PerformanceOficina.fromJson(Map<String, dynamic> json) =>
      PerformanceOficina(
        oficinaId: (json['oficinaId'] as num).toInt(),
        nome: json['nome'] as String,
        receita: (json['receita'] as num).toDouble(),
        totalOs: json['totalOs'] as int,
        ticketMedio: (json['ticketMedio'] as num).toDouble(),
        totalMecanicos: json['totalMecanicos'] as int,
        statusLabel: json['statusLabel'] as String,
      );
}

class RankingMecanico {
  const RankingMecanico({
    required this.posicao,
    required this.nome,
    required this.oficinaNome,
    required this.totalOs,
    required this.receita,
  });

  final int posicao;
  final String nome;
  final String oficinaNome;
  final int totalOs;
  final double receita;

  factory RankingMecanico.fromJson(Map<String, dynamic> json) => RankingMecanico(
        posicao: json['posicao'] as int,
        nome: json['nome'] as String,
        oficinaNome: json['oficinaNome'] as String,
        totalOs: json['totalOs'] as int,
        receita: (json['receita'] as num).toDouble(),
      );
}

class ReceitaTipo {
  const ReceitaTipo({
    required this.tipo,
    required this.valor,
    required this.percentual,
  });

  final String tipo;
  final double valor;
  final double percentual;

  factory ReceitaTipo.fromJson(Map<String, dynamic> json) => ReceitaTipo(
        tipo: json['tipo'] as String,
        valor: (json['valor'] as num).toDouble(),
        percentual: (json['percentual'] as num).toDouble(),
      );
}

class AlertaDetalhe {
  const AlertaDetalhe({required this.descricao, this.rota});
  final String descricao;
  final String? rota;

  factory AlertaDetalhe.fromJson(Map<String, dynamic> json) => AlertaDetalhe(
        descricao: json['descricao'] as String,
        rota: json['rota'] as String?,
      );
}

class Alerta {
  const Alerta({
    required this.tipo,
    required this.descricao,
    required this.nivel,
    required this.detalhes,
  });

  final String tipo;
  final String descricao;
  final String nivel;
  final List<AlertaDetalhe> detalhes;

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        tipo: json['tipo'] as String,
        descricao: json['descricao'] as String,
        nivel: json['nivel'] as String,
        detalhes: (json['detalhes'] as List<dynamic>)
            .map((e) => AlertaDetalhe.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GerencialDashboard {
  const GerencialDashboard({
    required this.receitaBruta,
    required this.receitaBrutaDeltaPct,
    required this.lucroLiquido,
    required this.margemLucro,
    required this.lucroDeltaPp,
    required this.totalOs,
    required this.totalOsDelta,
    required this.ticketMedio,
    required this.totalMecanicos,
    required this.capacidadeUtilizacao,
    required this.performancePorOficina,
    required this.rankingMecanicos,
    required this.receitaPorTipo,
    required this.alertas,
  });

  final double receitaBruta;
  final double receitaBrutaDeltaPct;
  final double lucroLiquido;
  final double margemLucro;
  final double lucroDeltaPp;
  final int totalOs;
  final int totalOsDelta;
  final double ticketMedio;
  final int totalMecanicos;
  final double capacidadeUtilizacao;
  final List<PerformanceOficina> performancePorOficina;
  final List<RankingMecanico> rankingMecanicos;
  final List<ReceitaTipo> receitaPorTipo;
  final List<Alerta> alertas;

  factory GerencialDashboard.fromJson(Map<String, dynamic> json) =>
      GerencialDashboard(
        receitaBruta: (json['receitaBruta'] as num).toDouble(),
        receitaBrutaDeltaPct: (json['receitaBrutaDeltaPct'] as num).toDouble(),
        lucroLiquido: (json['lucroLiquido'] as num).toDouble(),
        margemLucro: (json['margemLucro'] as num).toDouble(),
        lucroDeltaPp: (json['lucroDeltaPp'] as num).toDouble(),
        totalOs: json['totalOs'] as int,
        totalOsDelta: json['totalOsDelta'] as int,
        ticketMedio: (json['ticketMedio'] as num).toDouble(),
        totalMecanicos: json['totalMecanicos'] as int,
        capacidadeUtilizacao: (json['capacidadeUtilizacao'] as num).toDouble(),
        performancePorOficina: (json['performancePorOficina'] as List<dynamic>)
            .map((e) => PerformanceOficina.fromJson(e as Map<String, dynamic>))
            .toList(),
        rankingMecanicos: (json['rankingMecanicos'] as List<dynamic>)
            .map((e) => RankingMecanico.fromJson(e as Map<String, dynamic>))
            .toList(),
        receitaPorTipo: (json['receitaPorTipo'] as List<dynamic>)
            .map((e) => ReceitaTipo.fromJson(e as Map<String, dynamic>))
            .toList(),
        alertas: (json['alertas'] as List<dynamic>)
            .map((e) => Alerta.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
