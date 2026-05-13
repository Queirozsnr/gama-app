// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marca.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Marca _$MarcaFromJson(Map<String, dynamic> json) {
  return _Marca.fromJson(json);
}

/// @nodoc
mixin _$Marca {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;

  /// Serializes this Marca to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Marca
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MarcaCopyWith<Marca> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MarcaCopyWith<$Res> {
  factory $MarcaCopyWith(Marca value, $Res Function(Marca) then) =
      _$MarcaCopyWithImpl<$Res, Marca>;
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class _$MarcaCopyWithImpl<$Res, $Val extends Marca>
    implements $MarcaCopyWith<$Res> {
  _$MarcaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Marca
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? nome = null}) {
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MarcaImplCopyWith<$Res> implements $MarcaCopyWith<$Res> {
  factory _$$MarcaImplCopyWith(
    _$MarcaImpl value,
    $Res Function(_$MarcaImpl) then,
  ) = __$$MarcaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class __$$MarcaImplCopyWithImpl<$Res>
    extends _$MarcaCopyWithImpl<$Res, _$MarcaImpl>
    implements _$$MarcaImplCopyWith<$Res> {
  __$$MarcaImplCopyWithImpl(
    _$MarcaImpl _value,
    $Res Function(_$MarcaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Marca
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? nome = null}) {
    return _then(
      _$MarcaImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        nome: null == nome
            ? _value.nome
            : nome // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MarcaImpl implements _Marca {
  const _$MarcaImpl({required this.id, required this.nome});

  factory _$MarcaImpl.fromJson(Map<String, dynamic> json) =>
      _$$MarcaImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;

  @override
  String toString() {
    return 'Marca(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarcaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nome);

  /// Create a copy of Marca
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarcaImplCopyWith<_$MarcaImpl> get copyWith =>
      __$$MarcaImplCopyWithImpl<_$MarcaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MarcaImplToJson(this);
  }
}

abstract class _Marca implements Marca {
  const factory _Marca({required final int id, required final String nome}) =
      _$MarcaImpl;

  factory _Marca.fromJson(Map<String, dynamic> json) = _$MarcaImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;

  /// Create a copy of Marca
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarcaImplCopyWith<_$MarcaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
