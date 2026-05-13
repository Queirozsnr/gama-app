class FuncionarioAcumulado {
  const FuncionarioAcumulado({
    required this.funcionarioId,
    required this.nome,
    required this.cargo,
    required this.tipoRemuneracao,
    this.porcentagem,
    required this.osAbertasCount,
    required this.valorAcumulado,
    this.ultimoPagamentoEm,
    this.ultimoPagamentoId,
    this.pagamentoPendenteId,
  });

  final int funcionarioId;
  final String nome;
  final String cargo;
  final String tipoRemuneracao;
  final int? porcentagem;
  final int osAbertasCount;
  final double valorAcumulado;
  final DateTime? ultimoPagamentoEm;
  final int? ultimoPagamentoId;
  final int? pagamentoPendenteId;

  factory FuncionarioAcumulado.fromJson(Map<String, dynamic> json) => FuncionarioAcumulado(
        funcionarioId: json['funcionarioId'] as int,
        nome: json['nome'] as String,
        cargo: json['cargo'] as String,
        tipoRemuneracao: json['tipoRemuneracao'] as String,
        porcentagem: json['porcentagem'] as int?,
        osAbertasCount: json['osAbertasCount'] as int,
        valorAcumulado: (json['valorAcumulado'] as num).toDouble(),
        ultimoPagamentoEm: json['ultimoPagamentoEm'] != null
            ? DateTime.parse(json['ultimoPagamentoEm'] as String)
            : null,
        ultimoPagamentoId: json['ultimoPagamentoId'] as int?,
        pagamentoPendenteId: json['pagamentoPendenteId'] as int?,
      );
}

class PagamentoResumo {
  const PagamentoResumo({
    required this.id,
    required this.funcionarioId,
    required this.funcionarioNome,
    required this.tipoRemuneracao,
    required this.status,
    required this.valor,
    this.pagoEm,
    required this.criadoEm,
  });

  final int id;
  final int funcionarioId;
  final String funcionarioNome;
  final String tipoRemuneracao;
  final String status;
  final double valor;
  final DateTime? pagoEm;
  final DateTime criadoEm;

  factory PagamentoResumo.fromJson(Map<String, dynamic> json) => PagamentoResumo(
        id: json['id'] as int,
        funcionarioId: json['funcionarioId'] as int,
        funcionarioNome: json['funcionarioNome'] as String,
        tipoRemuneracao: json['tipoRemuneracao'] as String,
        status: json['status'] as String,
        valor: (json['valor'] as num).toDouble(),
        pagoEm: json['pagoEm'] != null ? DateTime.parse(json['pagoEm'] as String) : null,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );
}

class OsAberta {
  const OsAberta({
    required this.ordemServicoId,
    required this.clienteNome,
    required this.veiculoInfo,
    required this.dataEntrada,
    required this.totalOS,
    required this.valorContribuicao,
  });

  final int ordemServicoId;
  final String clienteNome;
  final String veiculoInfo;
  final DateTime dataEntrada;
  final double totalOS;
  final double valorContribuicao;

  factory OsAberta.fromJson(Map<String, dynamic> json) => OsAberta(
        ordemServicoId: json['ordemServicoId'] as int,
        clienteNome: json['clienteNome'] as String,
        veiculoInfo: json['veiculoInfo'] as String,
        dataEntrada: DateTime.parse(json['dataEntrada'] as String),
        totalOS: (json['totalOS'] as num).toDouble(),
        valorContribuicao: (json['valorContribuicao'] as num).toDouble(),
      );
}

class PagamentoDetalhe {
  const PagamentoDetalhe({
    required this.id,
    required this.funcionarioId,
    required this.funcionarioNome,
    required this.cargo,
    required this.tipoRemuneracao,
    this.porcentagem,
    required this.status,
    required this.valor,
    this.pagoEm,
    required this.criadoEm,
    required this.itens,
  });

  final int id;
  final int funcionarioId;
  final String funcionarioNome;
  final String cargo;
  final String tipoRemuneracao;
  final int? porcentagem;
  final String status;
  final double valor;
  final DateTime? pagoEm;
  final DateTime criadoEm;
  final List<PagamentoItemDetalhe> itens;

  factory PagamentoDetalhe.fromJson(Map<String, dynamic> json) => PagamentoDetalhe(
        id: json['id'] as int,
        funcionarioId: json['funcionarioId'] as int,
        funcionarioNome: json['funcionarioNome'] as String,
        cargo: json['cargo'] as String,
        tipoRemuneracao: json['tipoRemuneracao'] as String,
        porcentagem: json['porcentagem'] as int?,
        status: json['status'] as String,
        valor: (json['valor'] as num).toDouble(),
        pagoEm: json['pagoEm'] != null ? DateTime.parse(json['pagoEm'] as String) : null,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        itens: (json['itens'] as List<dynamic>)
            .map((e) => PagamentoItemDetalhe.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PagamentoItemDetalhe {
  const PagamentoItemDetalhe({
    required this.ordemServicoId,
    required this.clienteNome,
    required this.veiculoInfo,
    required this.dataEntrada,
    required this.totalOS,
    required this.valorContribuicao,
  });

  final int ordemServicoId;
  final String clienteNome;
  final String veiculoInfo;
  final DateTime dataEntrada;
  final double totalOS;
  final double valorContribuicao;

  factory PagamentoItemDetalhe.fromJson(Map<String, dynamic> json) => PagamentoItemDetalhe(
        ordemServicoId: json['ordemServicoId'] as int,
        clienteNome: json['clienteNome'] as String,
        veiculoInfo: json['veiculoInfo'] as String,
        dataEntrada: DateTime.parse(json['dataEntrada'] as String),
        totalOS: (json['totalOS'] as num).toDouble(),
        valorContribuicao: (json['valorContribuicao'] as num).toDouble(),
      );
}
