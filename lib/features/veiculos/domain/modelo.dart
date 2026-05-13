import 'package:freezed_annotation/freezed_annotation.dart';

part 'modelo.freezed.dart';
part 'modelo.g.dart';

@freezed
class Modelo with _$Modelo {
  const factory Modelo({
    required int id,
    required String nome,
    required int marcaId,
    required String marcaNome,
  }) = _Modelo;
  factory Modelo.fromJson(Map<String, dynamic> json) => _$ModeloFromJson(json);
}
