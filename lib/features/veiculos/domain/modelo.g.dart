// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modelo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModeloImpl _$$ModeloImplFromJson(Map<String, dynamic> json) => _$ModeloImpl(
  id: (json['id'] as num).toInt(),
  nome: json['nome'] as String,
  marcaId: (json['marcaId'] as num).toInt(),
  marcaNome: json['marcaNome'] as String,
);

Map<String, dynamic> _$$ModeloImplToJson(_$ModeloImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'marcaId': instance.marcaId,
      'marcaNome': instance.marcaNome,
    };
