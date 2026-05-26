import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'veiculo.freezed.dart';
part 'veiculo.g.dart';

@freezed
class Veiculo with _$Veiculo {
  const factory Veiculo({
    required int id,
    required int clienteId,
    required String clienteNome,
    required int modeloId,
    required String modeloNome,
    required int marcaId,
    required String marcaNome,
    String? placa,
    int? ano,
    String? cor,
    String? combustivel,
    double? cilindrada,
    int? quilometragem,
    String? observacoes,
    required bool ativo,
    required DateTime criadoEm,
  }) = _Veiculo;

  factory Veiculo.fromJson(Map<String, dynamic> json) => _$VeiculoFromJson(json);
}

/// Converts a Portuguese color name to a display color for the card banner.
Color corParaColor(String? cor) {
  return switch (cor?.toLowerCase().trim()) {
    'branco'                    => const Color(0xFFF0F0F0),
    'preto'                     => const Color(0xFF1C1C1C),
    'prata' || 'cinza' || 'cinza-escuro' => const Color(0xFF9E9E9E),
    'vermelho' || 'vinho'       => const Color(0xFFC62828),
    'azul' || 'azul-escuro'     => const Color(0xFF1565C0),
    'azul-claro'                => const Color(0xFF42A5F5),
    'verde'                     => const Color(0xFF2E7D32),
    'amarelo'                   => const Color(0xFFF9A825),
    'laranja'                   => const Color(0xFFE65100),
    'marrom'                    => const Color(0xFF5D4037),
    'bege'                      => const Color(0xFFD7C8A8),
    'roxo' || 'lilás'           => const Color(0xFF6A1B9A),
    'dourado' || 'ouro'         => const Color(0xFFB8860B),
    _                           => const Color(0xFF78909C),
  };
}
