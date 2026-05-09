// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'funcionario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FuncionarioImpl _$$FuncionarioImplFromJson(Map<String, dynamic> json) =>
    _$FuncionarioImpl(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      nome: json['nome'] as String,
      email: json['email'] as String,
      cargo: json['cargo'] as String,
      tipoRemuneracao: json['tipoRemuneracao'] as String,
      salario: (json['salario'] as num?)?.toDouble(),
      porcentagem: (json['porcentagem'] as num?)?.toDouble(),
      telefone: json['telefone'] as String?,
      ativo: json['ativo'] as bool,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      oficinas:
          (json['oficinas'] as List<dynamic>?)
              ?.map((e) => OficinaRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$FuncionarioImplToJson(_$FuncionarioImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'nome': instance.nome,
      'email': instance.email,
      'cargo': instance.cargo,
      'tipoRemuneracao': instance.tipoRemuneracao,
      'salario': instance.salario,
      'porcentagem': instance.porcentagem,
      'telefone': instance.telefone,
      'ativo': instance.ativo,
      'criadoEm': instance.criadoEm.toIso8601String(),
      'oficinas': instance.oficinas,
    };

_$OficinaRefImpl _$$OficinaRefImplFromJson(Map<String, dynamic> json) =>
    _$OficinaRefImpl(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
    );

Map<String, dynamic> _$$OficinaRefImplToJson(_$OficinaRefImpl instance) =>
    <String, dynamic>{'id': instance.id, 'nome': instance.nome};
