class VeiculoResumo {
  const VeiculoResumo({required this.id, this.placa, required this.modeloNome, this.cor});

  final int id;
  final String? placa;
  final String modeloNome;
  final String? cor;

  factory VeiculoResumo.fromJson(Map<String, dynamic> json) => VeiculoResumo(
        id: json['id'] as int,
        placa: json['placa'] as String?,
        modeloNome: json['modeloNome'] as String,
        cor: json['cor'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'placa': placa, 'modeloNome': modeloNome, 'cor': cor};

  String get label {
    final cor = this.cor;
    return cor != null ? '$modeloNome · $cor' : modeloNome;
  }
}
