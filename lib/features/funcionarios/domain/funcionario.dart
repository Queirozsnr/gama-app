import 'package:freezed_annotation/freezed_annotation.dart';

part 'funcionario.freezed.dart';
part 'funcionario.g.dart';

@freezed
class Funcionario with _$Funcionario {
  const factory Funcionario({
    required int id,
    required int userId,
    required String nome,
    required String email,
    required String cargo,
    required String tipoRemuneracao,
    double? salario,
    double? porcentagem,
    String? telefone,
    required bool ativo,
    required DateTime criadoEm,
    @Default([]) List<OficinaRef> oficinas,
  }) = _Funcionario;

  factory Funcionario.fromJson(Map<String, dynamic> json) => _$FuncionarioFromJson(json);
}

@freezed
class OficinaRef with _$OficinaRef {
  const factory OficinaRef({
    required int id,
    required String nome,
  }) = _OficinaRef;

  factory OficinaRef.fromJson(Map<String, dynamic> json) => _$OficinaRefFromJson(json);
}
