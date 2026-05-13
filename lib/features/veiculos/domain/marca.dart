import 'package:freezed_annotation/freezed_annotation.dart';

part 'marca.freezed.dart';
part 'marca.g.dart';

@freezed
class Marca with _$Marca {
  const factory Marca({required int id, required String nome}) = _Marca;
  factory Marca.fromJson(Map<String, dynamic> json) => _$MarcaFromJson(json);
}
