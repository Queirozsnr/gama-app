class ResumoEstoque {
  const ResumoEstoque({
    required this.totalEmEstoque,
    required this.totalSkus,
    required this.totalUnidades,
    required this.itensCriticos,
    required this.entradasUltimos7Dias,
    required this.saidasUltimos7Dias,
    this.comprasPendentes = 0,
  });

  final double totalEmEstoque;
  final int totalSkus;
  final int totalUnidades;
  final int itensCriticos;
  final int entradasUltimos7Dias;
  final int saidasUltimos7Dias;
  final int comprasPendentes;

  factory ResumoEstoque.fromJson(Map<String, dynamic> json) => ResumoEstoque(
        totalEmEstoque: (json['totalEmEstoque'] as num).toDouble(),
        totalSkus: json['totalSkus'] as int,
        totalUnidades: json['totalUnidades'] as int,
        itensCriticos: json['itensCriticos'] as int,
        entradasUltimos7Dias: json['entradasUltimos7Dias'] as int,
        saidasUltimos7Dias: json['saidasUltimos7Dias'] as int,
        comprasPendentes: json['comprasPendentes'] as int? ?? 0,
      );
}

class ProdutoListagem {
  const ProdutoListagem({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.categoria,
    required this.unidade,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
    required this.precoVenda,
    required this.status,
    this.ultimaEntradaEm,
  });

  final int id;
  final String nome;
  final String codigo;
  final String categoria;
  final String unidade;
  final double quantidadeAtual;
  final double quantidadeMinima;
  final double precoVenda;
  final String status; // Ok | Baixo | Critico
  final DateTime? ultimaEntradaEm;

  factory ProdutoListagem.fromJson(Map<String, dynamic> json) => ProdutoListagem(
        id: json['id'] as int,
        nome: json['nome'] as String,
        codigo: json['codigo'] as String,
        categoria: json['categoria'] as String,
        unidade: json['unidade'] as String,
        quantidadeAtual: (json['quantidadeAtual'] as num).toDouble(),
        quantidadeMinima: (json['quantidadeMinima'] as num).toDouble(),
        precoVenda: (json['precoVenda'] as num).toDouble(),
        status: json['status'] as String,
        ultimaEntradaEm: json['ultimaEntradaEm'] != null
            ? DateTime.parse(json['ultimaEntradaEm'] as String)
            : null,
      );
}

class FornecedorEstoque {
  const FornecedorEstoque({
    required this.id,
    required this.nome,
    this.telefone,
    this.email,
  });

  final int id;
  final String nome;
  final String? telefone;
  final String? email;

  factory FornecedorEstoque.fromJson(Map<String, dynamic> json) => FornecedorEstoque(
        id: json['id'] as int,
        nome: json['nome'] as String,
        telefone: json['telefone'] as String?,
        email: json['email'] as String?,
      );
}

class MovimentacaoEstoque {
  const MovimentacaoEstoque({
    required this.id,
    required this.tipo,
    required this.quantidade,
    this.precoUnitario,
    this.fornecedorNome,
    this.observacao,
    required this.criadoEm,
  });

  final int id;
  final String tipo; // Entrada | Saida | Ajuste
  final double quantidade;
  final double? precoUnitario;
  final String? fornecedorNome;
  final String? observacao;
  final DateTime criadoEm;

  factory MovimentacaoEstoque.fromJson(Map<String, dynamic> json) => MovimentacaoEstoque(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        quantidade: (json['quantidade'] as num).toDouble(),
        precoUnitario: json['precoUnitario'] != null
            ? (json['precoUnitario'] as num).toDouble()
            : null,
        fornecedorNome: json['fornecedorNome'] as String?,
        observacao: json['observacao'] as String?,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );
}
