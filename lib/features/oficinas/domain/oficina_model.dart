class OficinaModel {
  const OficinaModel({
    required this.id,
    required this.grupoOficinaId,
    required this.nome,
    required this.endereco,
    required this.telefone,
    required this.ativo,
    required this.criadoEm,
  });

  final int id;
  final int grupoOficinaId;
  final String nome;
  final String endereco;
  final String telefone;
  final bool ativo;
  final DateTime criadoEm;

  factory OficinaModel.fromJson(Map<String, dynamic> json) => OficinaModel(
        id: (json['id'] as num).toInt(),
        grupoOficinaId: (json['grupoOficinaId'] as num).toInt(),
        nome: json['nome'] as String? ?? '',
        endereco: json['endereco'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        ativo: json['ativo'] as bool? ?? true,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  OficinaModel copyWith({String? nome, String? endereco, String? telefone, bool? ativo}) =>
      OficinaModel(
        id: id,
        grupoOficinaId: grupoOficinaId,
        nome: nome ?? this.nome,
        endereco: endereco ?? this.endereco,
        telefone: telefone ?? this.telefone,
        ativo: ativo ?? this.ativo,
        criadoEm: criadoEm,
      );
}
