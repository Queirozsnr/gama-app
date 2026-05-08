// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginResponseImpl _$$LoginResponseImplFromJson(Map<String, dynamic> json) =>
    _$LoginResponseImpl(
      token: json['token'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      grupoOficinaId: (json['grupoOficinaId'] as num?)?.toInt(),
      selecioneGrupo: (json['selecioneGrupo'] as List<dynamic>?)
          ?.map((e) => GrupoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LoginResponseImplToJson(_$LoginResponseImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'grupoOficinaId': instance.grupoOficinaId,
      'selecioneGrupo': instance.selecioneGrupo,
    };

_$SelectGroupResponseImpl _$$SelectGroupResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SelectGroupResponseImpl(
  token: json['token'] as String,
  userId: (json['userId'] as num).toInt(),
  grupoOficinaId: (json['grupoOficinaId'] as num).toInt(),
);

Map<String, dynamic> _$$SelectGroupResponseImplToJson(
  _$SelectGroupResponseImpl instance,
) => <String, dynamic>{
  'token': instance.token,
  'userId': instance.userId,
  'grupoOficinaId': instance.grupoOficinaId,
};

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map<String, dynamic> json) =>
    _$LoginRequestImpl(
      email: json['email'] as String,
      senha: json['senha'] as String,
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{'email': instance.email, 'senha': instance.senha};

_$SelectGroupRequestImpl _$$SelectGroupRequestImplFromJson(
  Map<String, dynamic> json,
) => _$SelectGroupRequestImpl(
  userId: (json['userId'] as num).toInt(),
  grupoOficinaId: (json['grupoOficinaId'] as num).toInt(),
);

Map<String, dynamic> _$$SelectGroupRequestImplToJson(
  _$SelectGroupRequestImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'grupoOficinaId': instance.grupoOficinaId,
};
