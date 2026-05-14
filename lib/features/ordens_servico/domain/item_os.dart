class ItemOs {
  const ItemOs({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.subtotal,
    this.origemPeca,
    this.produtoId,
  });

  final int id;
  final String tipo; // 'Servico' | 'Peca'
  final String descricao;
  final double quantidade;
  final double valorUnitario;
  final double subtotal;
  final String? origemPeca; // 'Estoque' | 'Comprado' | 'ClienteTrouxe'
  final int? produtoId;

  bool get isPeca => tipo == 'Peca';

  factory ItemOs.fromJson(Map<String, dynamic> json) => ItemOs(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        descricao: json['descricao'] as String,
        quantidade: (json['quantidade'] as num).toDouble(),
        valorUnitario: (json['valorUnitario'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
        origemPeca: json['origemPeca'] as String?,
        produtoId: json['produtoId'] as int?,
      );
}
