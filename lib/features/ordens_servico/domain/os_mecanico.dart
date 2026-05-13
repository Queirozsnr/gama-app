class OsMecanico {
  const OsMecanico({
    required this.funcionarioId,
    required this.nome,
    required this.cargo,
    required this.ingressouEm,
  });

  final int funcionarioId;
  final String nome;
  final String cargo;
  final DateTime ingressouEm;

  factory OsMecanico.fromJson(Map<String, dynamic> json) => OsMecanico(
        funcionarioId: json['funcionarioId'] as int,
        nome: json['nome'] as String,
        cargo: json['cargo'] as String,
        ingressouEm: DateTime.parse(json['ingressouEm'] as String),
      );
}
