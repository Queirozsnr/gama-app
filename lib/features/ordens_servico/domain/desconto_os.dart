class DescontoOs {
  const DescontoOs({required this.id, required this.descricao, required this.valor});
  final int id;
  final String descricao;
  final double valor;

  factory DescontoOs.fromJson(Map<String, dynamic> json) => DescontoOs(
        id: json['id'] as int,
        descricao: json['descricao'] as String,
        valor: (json['valor'] as num).toDouble(),
      );
}
