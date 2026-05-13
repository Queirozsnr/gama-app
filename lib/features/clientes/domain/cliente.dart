import 'package:freezed_annotation/freezed_annotation.dart';
import 'veiculo_resumo.dart';

part 'cliente.freezed.dart';
part 'cliente.g.dart';

@freezed
class Cliente with _$Cliente {
  const factory Cliente({
    required int id,
    required String nome,
    String? email,
    String? telefone,
    String? cpf,
    String? cidade,
    required bool ativo,
    required DateTime criadoEm,
    @Default([]) List<VeiculoResumo> veiculos,
  }) = _Cliente;

  factory Cliente.fromJson(Map<String, dynamic> json) => _$ClienteFromJson(json);
}
