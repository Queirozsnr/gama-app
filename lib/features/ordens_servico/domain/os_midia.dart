class OsMidia {
  const OsMidia({
    required this.id,
    required this.url,
    required this.tipo,
    required this.criadoPorNome,
    required this.criadoEm,
  });

  final int id;
  final String url;
  final String tipo; // "Imagem" | "Video"
  final String criadoPorNome;
  final DateTime criadoEm;

  bool get isVideo => tipo == 'Video';

  factory OsMidia.fromJson(Map<String, dynamic> json) => OsMidia(
        id: json['id'] as int,
        url: json['url'] as String,
        tipo: json['tipo'] as String,
        criadoPorNome: json['criadoPorNome'] as String,
        criadoEm: DateTime.parse(json['criadoEm'] as String).toLocal(),
      );
}
