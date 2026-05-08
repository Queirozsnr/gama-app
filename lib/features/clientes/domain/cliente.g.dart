// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClienteImpl _$$ClienteImplFromJson(Map<String, dynamic> json) =>
    _$ClienteImpl(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      cpf: json['cpf'] as String?,
      cidade: json['cidade'] as String?,
      ativo: json['ativo'] as bool,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
    );

Map<String, dynamic> _$$ClienteImplToJson(_$ClienteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'email': instance.email,
      'telefone': instance.telefone,
      'cpf': instance.cpf,
      'cidade': instance.cidade,
      'ativo': instance.ativo,
      'criadoEm': instance.criadoEm.toIso8601String(),
    };
