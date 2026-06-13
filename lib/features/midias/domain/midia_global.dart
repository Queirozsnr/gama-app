class MidiaGlobal {
  const MidiaGlobal({
    required this.id,
    required this.osId,
    required this.clienteNome,
    required this.veiculoDescricao,
    this.veiculoPlaca,
    required this.url,
    required this.tipo,
    required this.tamanhoBytes,
    required this.criadoPorNome,
    required this.criadoEm,
  });

  final int id;
  final int osId;
  final String clienteNome;
  final String veiculoDescricao;
  final String? veiculoPlaca;
  final String url;
  final String tipo; // 'Imagem' | 'Video'
  final int tamanhoBytes;
  final String criadoPorNome;
  final DateTime criadoEm;

  bool get isVideo => tipo == 'Video';

  factory MidiaGlobal.fromJson(Map<String, dynamic> json) => MidiaGlobal(
        id: (json['id'] as num).toInt(),
        osId: (json['osId'] as num).toInt(),
        clienteNome: json['clienteNome'] as String? ?? '',
        veiculoDescricao: json['veiculoDescricao'] as String? ?? '',
        veiculoPlaca: json['veiculoPlaca'] as String?,
        url: json['url'] as String,
        tipo: json['tipo'] as String,
        tamanhoBytes: (json['tamanhoBytes'] as num).toInt(),
        criadoPorNome: json['criadoPorNome'] as String,
        criadoEm: DateTime.parse(json['criadoEm'] as String).toLocal(),
      );
}
