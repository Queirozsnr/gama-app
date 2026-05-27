class Notificacao {
  final int id;
  final String tipo;
  final String titulo;
  final String corpo;
  final int? referenciaId;
  final bool lida;
  final DateTime criadaEm;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    this.referenciaId,
    required this.lida,
    required this.criadaEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) => Notificacao(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        titulo: json['titulo'] as String,
        corpo: json['corpo'] as String,
        referenciaId: json['referenciaId'] as int?,
        lida: json['lida'] as bool,
        criadaEm: DateTime.parse(json['criadaEm'] as String),
      );

  Notificacao copyWith({bool? lida}) => Notificacao(
        id: id,
        tipo: tipo,
        titulo: titulo,
        corpo: corpo,
        referenciaId: referenciaId,
        lida: lida ?? this.lida,
        criadaEm: criadaEm,
      );
}
