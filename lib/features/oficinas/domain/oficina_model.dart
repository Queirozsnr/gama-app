class OficinaModel {
  const OficinaModel({
    required this.id,
    required this.grupoOficinaId,
    required this.nome,
    required this.endereco,
    required this.telefone,
    this.telefone2,
    this.email,
    this.whatsapp,
    this.instagram,
    this.cnpj,
    this.corPadrao,
    this.logoUrl,
    required this.ativo,
    required this.criadoEm,
  });

  final int id;
  final int grupoOficinaId;
  final String nome;
  final String endereco;
  final String telefone;
  final String? telefone2;
  final String? email;
  final String? whatsapp;
  final String? instagram;
  final String? cnpj;
  final String? corPadrao;
  final String? logoUrl;
  final bool ativo;
  final DateTime criadoEm;

  factory OficinaModel.fromJson(Map<String, dynamic> json) => OficinaModel(
        id: (json['id'] as num).toInt(),
        grupoOficinaId: (json['grupoOficinaId'] as num).toInt(),
        nome: json['nome'] as String? ?? '',
        endereco: json['endereco'] as String? ?? '',
        telefone: json['telefone'] as String? ?? '',
        telefone2: json['telefone2'] as String?,
        email: json['email'] as String?,
        whatsapp: json['whatsapp'] as String?,
        instagram: json['instagram'] as String?,
        cnpj: json['cnpj'] as String?,
        corPadrao: json['corPadrao'] as String?,
        logoUrl: json['logoUrl'] as String?,
        ativo: json['ativo'] as bool? ?? true,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  OficinaModel copyWith({
    String? nome,
    String? endereco,
    String? telefone,
    String? telefone2,
    String? email,
    String? whatsapp,
    String? instagram,
    String? cnpj,
    String? corPadrao,
    String? logoUrl,
    bool? ativo,
  }) =>
      OficinaModel(
        id: id,
        grupoOficinaId: grupoOficinaId,
        nome: nome ?? this.nome,
        endereco: endereco ?? this.endereco,
        telefone: telefone ?? this.telefone,
        telefone2: telefone2 ?? this.telefone2,
        email: email ?? this.email,
        whatsapp: whatsapp ?? this.whatsapp,
        instagram: instagram ?? this.instagram,
        cnpj: cnpj ?? this.cnpj,
        corPadrao: corPadrao ?? this.corPadrao,
        logoUrl: logoUrl ?? this.logoUrl,
        ativo: ativo ?? this.ativo,
        criadoEm: criadoEm,
      );
}
