// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modelo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Modelo _$ModeloFromJson(Map<String, dynamic> json) {
  return _Modelo.fromJson(json);
}

/// @nodoc
mixin _$Modelo {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;
  int get marcaId => throw _privateConstructorUsedError;
  String get marcaNome => throw _privateConstructorUsedError;

  /// Serializes this Modelo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Modelo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModeloCopyWith<Modelo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModeloCopyWith<$Res> {
  factory $ModeloCopyWith(Modelo value, $Res Function(Modelo) then) =
      _$ModeloCopyWithImpl<$Res, Modelo>;
  @useResult
  $Res call({int id, String nome, int marcaId, String marcaNome});
}

/// @nodoc
class _$ModeloCopyWithImpl<$Res, $Val extends Modelo>
    implements $ModeloCopyWith<$Res> {
  _$ModeloCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Modelo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nome = null,
    Object? marcaId = null,
    Object? marcaNome = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            nome: null == nome
                ? _value.nome
                : nome // ignore: cast_nullable_to_non_nullable
                      as String,
            marcaId: null == marcaId
                ? _value.marcaId
                : marcaId // ignore: cast_nullable_to_non_nullable
                      as int,
            marcaNome: null == marcaNome
                ? _value.marcaNome
                : marcaNome // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModeloImplCopyWith<$Res> implements $ModeloCopyWith<$Res> {
  factory _$$ModeloImplCopyWith(
    _$ModeloImpl value,
    $Res Function(_$ModeloImpl) then,
  ) = __$$ModeloImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String nome, int marcaId, String marcaNome});
}

/// @nodoc
class __$$ModeloImplCopyWithImpl<$Res>
    extends _$ModeloCopyWithImpl<$Res, _$ModeloImpl>
    implements _$$ModeloImplCopyWith<$Res> {
  __$$ModeloImplCopyWithImpl(
    _$ModeloImpl _value,
    $Res Function(_$ModeloImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Modelo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nome = null,
    Object? marcaId = null,
    Object? marcaNome = null,
  }) {
    return _then(
      _$ModeloImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        nome: null == nome
            ? _value.nome
            : nome // ignore: cast_nullable_to_non_nullable
                  as String,
        marcaId: null == marcaId
            ? _value.marcaId
            : marcaId // ignore: cast_nullable_to_non_nullable
                  as int,
        marcaNome: null == marcaNome
            ? _value.marcaNome
            : marcaNome // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModeloImpl implements _Modelo {
  const _$ModeloImpl({
    required this.id,
    required this.nome,
    required this.marcaId,
    required this.marcaNome,
  });

  factory _$ModeloImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModeloImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;
  @override
  final int marcaId;
  @override
  final String marcaNome;

  @override
  String toString() {
    return 'Modelo(id: $id, nome: $nome, marcaId: $marcaId, marcaNome: $marcaNome)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModeloImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome) &&
            (identical(other.marcaId, marcaId) || other.marcaId == marcaId) &&
            (identical(other.marcaNome, marcaNome) ||
                other.marcaNome == marcaNome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nome, marcaId, marcaNome);

  /// Create a copy of Modelo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModeloImplCopyWith<_$ModeloImpl> get copyWith =>
      __$$ModeloImplCopyWithImpl<_$ModeloImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModeloImplToJson(this);
  }
}

abstract class _Modelo implements Modelo {
  const factory _Modelo({
    required final int id,
    required final String nome,
    required final int marcaId,
    required final String marcaNome,
  }) = _$ModeloImpl;

  factory _Modelo.fromJson(Map<String, dynamic> json) = _$ModeloImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;
  @override
  int get marcaId;
  @override
  String get marcaNome;

  /// Create a copy of Modelo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModeloImplCopyWith<_$ModeloImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
