// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GrupoItemImpl _$$GrupoItemImplFromJson(Map<String, dynamic> json) =>
    _$GrupoItemImpl(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
    );

Map<String, dynamic> _$$GrupoItemImplToJson(_$GrupoItemImpl instance) =>
    <String, dynamic>{'id': instance.id, 'nome': instance.nome};

_$OficinaItemImpl _$$OficinaItemImplFromJson(Map<String, dynamic> json) =>
    _$OficinaItemImpl(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      osAbertas: (json['osAbertas'] as num?)?.toInt() ?? 0,
      equipeCount: (json['equipeCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$OficinaItemImplToJson(_$OficinaItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'osAbertas': instance.osAbertas,
      'equipeCount': instance.equipeCount,
    };
