// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cliente.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Cliente _$ClienteFromJson(Map<String, dynamic> json) {
  return _Cliente.fromJson(json);
}

/// @nodoc
mixin _$Cliente {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get telefone => throw _privateConstructorUsedError;
  String? get cpf => throw _privateConstructorUsedError;
  String? get cidade => throw _privateConstructorUsedError;
  bool get ativo => throw _privateConstructorUsedError;
  DateTime get criadoEm => throw _privateConstructorUsedError;
  List<VeiculoResumo> get veiculos => throw _privateConstructorUsedError;

  /// Serializes this Cliente to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Cliente
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClienteCopyWith<Cliente> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClienteCopyWith<$Res> {
  factory $ClienteCopyWith(Cliente value, $Res Function(Cliente) then) =
      _$ClienteCopyWithImpl<$Res, Cliente>;
  @useResult
  $Res call({
    int id,
    String nome,
    String? email,
    String? telefone,
    String? cpf,
    String? cidade,
    bool ativo,
    DateTime criadoEm,
    List<VeiculoResumo> veiculos,
  });
}

/// @nodoc
class _$ClienteCopyWithImpl<$Res, $Val extends Cliente>
    implements $ClienteCopyWith<$Res> {
  _$ClienteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Cliente
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nome = null,
    Object? email = freezed,
    Object? telefone = freezed,
    Object? cpf = freezed,
    Object? cidade = freezed,
    Object? ativo = null,
    Object? criadoEm = null,
    Object? veiculos = null,
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
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            telefone: freezed == telefone
                ? _value.telefone
                : telefone // ignore: cast_nullable_to_non_nullable
                      as String?,
            cpf: freezed == cpf
                ? _value.cpf
                : cpf // ignore: cast_nullable_to_non_nullable
                      as String?,
            cidade: freezed == cidade
                ? _value.cidade
                : cidade // ignore: cast_nullable_to_non_nullable
                      as String?,
            ativo: null == ativo
                ? _value.ativo
                : ativo // ignore: cast_nullable_to_non_nullable
                      as bool,
            criadoEm: null == criadoEm
                ? _value.criadoEm
                : criadoEm // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            veiculos: null == veiculos
                ? _value.veiculos
                : veiculos // ignore: cast_nullable_to_non_nullable
                      as List<VeiculoResumo>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClienteImplCopyWith<$Res> implements $ClienteCopyWith<$Res> {
  factory _$$ClienteImplCopyWith(
    _$ClienteImpl value,
    $Res Function(_$ClienteImpl) then,
  ) = __$$ClienteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String nome,
    String? email,
    String? telefone,
    String? cpf,
    String? cidade,
    bool ativo,
    DateTime criadoEm,
    List<VeiculoResumo> veiculos,
  });
}

/// @nodoc
class __$$ClienteImplCopyWithImpl<$Res>
    extends _$ClienteCopyWithImpl<$Res, _$ClienteImpl>
    implements _$$ClienteImplCopyWith<$Res> {
  __$$ClienteImplCopyWithImpl(
    _$ClienteImpl _value,
    $Res Function(_$ClienteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Cliente
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nome = null,
    Object? email = freezed,
    Object? telefone = freezed,
    Object? cpf = freezed,
    Object? cidade = freezed,
    Object? ativo = null,
    Object? criadoEm = null,
    Object? veiculos = null,
  }) {
    return _then(
      _$ClienteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        nome: null == nome
            ? _value.nome
            : nome // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        telefone: freezed == telefone
            ? _value.telefone
            : telefone // ignore: cast_nullable_to_non_nullable
                  as String?,
        cpf: freezed == cpf
            ? _value.cpf
            : cpf // ignore: cast_nullable_to_non_nullable
                  as String?,
        cidade: freezed == cidade
            ? _value.cidade
            : cidade // ignore: cast_nullable_to_non_nullable
                  as String?,
        ativo: null == ativo
            ? _value.ativo
            : ativo // ignore: cast_nullable_to_non_nullable
                  as bool,
        criadoEm: null == criadoEm
            ? _value.criadoEm
            : criadoEm // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        veiculos: null == veiculos
            ? _value._veiculos
            : veiculos // ignore: cast_nullable_to_non_nullable
                  as List<VeiculoResumo>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClienteImpl implements _Cliente {
  const _$ClienteImpl({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.cpf,
    this.cidade,
    required this.ativo,
    required this.criadoEm,
    final List<VeiculoResumo> veiculos = const [],
  }) : _veiculos = veiculos;

  factory _$ClienteImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClienteImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;
  @override
  final String? email;
  @override
  final String? telefone;
  @override
  final String? cpf;
  @override
  final String? cidade;
  @override
  final bool ativo;
  @override
  final DateTime criadoEm;
  final List<VeiculoResumo> _veiculos;
  @override
  @JsonKey()
  List<VeiculoResumo> get veiculos {
    if (_veiculos is EqualUnmodifiableListView) return _veiculos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_veiculos);
  }

  @override
  String toString() {
    return 'Cliente(id: $id, nome: $nome, email: $email, telefone: $telefone, cpf: $cpf, cidade: $cidade, ativo: $ativo, criadoEm: $criadoEm, veiculos: $veiculos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClienteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.telefone, telefone) ||
                other.telefone == telefone) &&
            (identical(other.cpf, cpf) || other.cpf == cpf) &&
            (identical(other.cidade, cidade) || other.cidade == cidade) &&
            (identical(other.ativo, ativo) || other.ativo == ativo) &&
            (identical(other.criadoEm, criadoEm) ||
                other.criadoEm == criadoEm) &&
            const DeepCollectionEquality().equals(other._veiculos, _veiculos));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nome,
    email,
    telefone,
    cpf,
    cidade,
    ativo,
    criadoEm,
    const DeepCollectionEquality().hash(_veiculos),
  );

  /// Create a copy of Cliente
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClienteImplCopyWith<_$ClienteImpl> get copyWith =>
      __$$ClienteImplCopyWithImpl<_$ClienteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClienteImplToJson(this);
  }
}

abstract class _Cliente implements Cliente {
  const factory _Cliente({
    required final int id,
    required final String nome,
    final String? email,
    final String? telefone,
    final String? cpf,
    final String? cidade,
    required final bool ativo,
    required final DateTime criadoEm,
    final List<VeiculoResumo> veiculos,
  }) = _$ClienteImpl;

  factory _Cliente.fromJson(Map<String, dynamic> json) = _$ClienteImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;
  @override
  String? get email;
  @override
  String? get telefone;
  @override
  String? get cpf;
  @override
  String? get cidade;
  @override
  bool get ativo;
  @override
  DateTime get criadoEm;
  @override
  List<VeiculoResumo> get veiculos;

  /// Create a copy of Cliente
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClienteImplCopyWith<_$ClienteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
