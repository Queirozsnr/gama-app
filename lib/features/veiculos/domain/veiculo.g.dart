// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veiculo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VeiculoImpl _$$VeiculoImplFromJson(Map<String, dynamic> json) =>
    _$VeiculoImpl(
      id: (json['id'] as num).toInt(),
      clienteId: (json['clienteId'] as num).toInt(),
      clienteNome: json['clienteNome'] as String,
      modeloId: (json['modeloId'] as num).toInt(),
      modeloNome: json['modeloNome'] as String,
      marcaId: (json['marcaId'] as num).toInt(),
      marcaNome: json['marcaNome'] as String,
      placa: json['placa'] as String?,
      ano: (json['ano'] as num?)?.toInt(),
      cor: json['cor'] as String?,
      combustivel: json['combustivel'] as String?,
      cilindrada: (json['cilindrada'] as num?)?.toDouble(),
      quilometragem: (json['quilometragem'] as num?)?.toInt(),
      observacoes: json['observacoes'] as String?,
      ativo: json['ativo'] as bool,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
    );

Map<String, dynamic> _$$VeiculoImplToJson(_$VeiculoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clienteId': instance.clienteId,
      'clienteNome': instance.clienteNome,
      'modeloId': instance.modeloId,
      'modeloNome': instance.modeloNome,
      'marcaId': instance.marcaId,
      'marcaNome': instance.marcaNome,
      'placa': instance.placa,
      'ano': instance.ano,
      'cor': instance.cor,
      'combustivel': instance.combustivel,
      'cilindrada': instance.cilindrada,
      'quilometragem': instance.quilometragem,
      'observacoes': instance.observacoes,
      'ativo': instance.ativo,
      'criadoEm': instance.criadoEm.toIso8601String(),
    };
