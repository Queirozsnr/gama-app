// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'funcionario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Funcionario _$FuncionarioFromJson(Map<String, dynamic> json) {
  return _Funcionario.fromJson(json);
}

/// @nodoc
mixin _$Funcionario {
  int get id => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get cargo => throw _privateConstructorUsedError;
  String get tipoRemuneracao => throw _privateConstructorUsedError;
  double? get salario => throw _privateConstructorUsedError;
  double? get porcentagem => throw _privateConstructorUsedError;
  String? get telefone => throw _privateConstructorUsedError;
  bool get ativo => throw _privateConstructorUsedError;
  DateTime get criadoEm => throw _privateConstructorUsedError;
  List<OficinaRef> get oficinas => throw _privateConstructorUsedError;

  /// Serializes this Funcionario to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Funcionario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FuncionarioCopyWith<Funcionario> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FuncionarioCopyWith<$Res> {
  factory $FuncionarioCopyWith(
    Funcionario value,
    $Res Function(Funcionario) then,
  ) = _$FuncionarioCopyWithImpl<$Res, Funcionario>;
  @useResult
  $Res call({
    int id,
    int userId,
    String nome,
    String email,
    String cargo,
    String tipoRemuneracao,
    double? salario,
    double? porcentagem,
    String? telefone,
    bool ativo,
    DateTime criadoEm,
    List<OficinaRef> oficinas,
  });
}

/// @nodoc
class _$FuncionarioCopyWithImpl<$Res, $Val extends Funcionario>
    implements $FuncionarioCopyWith<$Res> {
  _$FuncionarioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Funcionario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? nome = null,
    Object? email = null,
    Object? cargo = null,
    Object? tipoRemuneracao = null,
    Object? salario = freezed,
    Object? porcentagem = freezed,
    Object? telefone = freezed,
    Object? ativo = null,
    Object? criadoEm = null,
    Object? oficinas = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            nome: null == nome
                ? _value.nome
                : nome // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            cargo: null == cargo
                ? _value.cargo
                : cargo // ignore: cast_nullable_to_non_nullable
                      as String,
            tipoRemuneracao: null == tipoRemuneracao
                ? _value.tipoRemuneracao
                : tipoRemuneracao // ignore: cast_nullable_to_non_nullable
                      as String,
            salario: freezed == salario
                ? _value.salario
                : salario // ignore: cast_nullable_to_non_nullable
                      as double?,
            porcentagem: freezed == porcentagem
                ? _value.porcentagem
                : porcentagem // ignore: cast_nullable_to_non_nullable
                      as double?,
            telefone: freezed == telefone
                ? _value.telefone
                : telefone // ignore: cast_nullable_to_non_nullable
                      as String?,
            ativo: null == ativo
                ? _value.ativo
                : ativo // ignore: cast_nullable_to_non_nullable
                      as bool,
            criadoEm: null == criadoEm
                ? _value.criadoEm
                : criadoEm // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            oficinas: null == oficinas
                ? _value.oficinas
                : oficinas // ignore: cast_nullable_to_non_nullable
                      as List<OficinaRef>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FuncionarioImplCopyWith<$Res>
    implements $FuncionarioCopyWith<$Res> {
  factory _$$FuncionarioImplCopyWith(
    _$FuncionarioImpl value,
    $Res Function(_$FuncionarioImpl) then,
  ) = __$$FuncionarioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int userId,
    String nome,
    String email,
    String cargo,
    String tipoRemuneracao,
    double? salario,
    double? porcentagem,
    String? telefone,
    bool ativo,
    DateTime criadoEm,
    List<OficinaRef> oficinas,
  });
}

/// @nodoc
class __$$FuncionarioImplCopyWithImpl<$Res>
    extends _$FuncionarioCopyWithImpl<$Res, _$FuncionarioImpl>
    implements _$$FuncionarioImplCopyWith<$Res> {
  __$$FuncionarioImplCopyWithImpl(
    _$FuncionarioImpl _value,
    $Res Function(_$FuncionarioImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Funcionario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? nome = null,
    Object? email = null,
    Object? cargo = null,
    Object? tipoRemuneracao = null,
    Object? salario = freezed,
    Object? porcentagem = freezed,
    Object? telefone = freezed,
    Object? ativo = null,
    Object? criadoEm = null,
    Object? oficinas = null,
  }) {
    return _then(
      _$FuncionarioImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        nome: null == nome
            ? _value.nome
            : nome // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        cargo: null == cargo
            ? _value.cargo
            : cargo // ignore: cast_nullable_to_non_nullable
                  as String,
        tipoRemuneracao: null == tipoRemuneracao
            ? _value.tipoRemuneracao
            : tipoRemuneracao // ignore: cast_nullable_to_non_nullable
                  as String,
        salario: freezed == salario
            ? _value.salario
            : salario // ignore: cast_nullable_to_non_nullable
                  as double?,
        porcentagem: freezed == porcentagem
            ? _value.porcentagem
            : porcentagem // ignore: cast_nullable_to_non_nullable
                  as double?,
        telefone: freezed == telefone
            ? _value.telefone
            : telefone // ignore: cast_nullable_to_non_nullable
                  as String?,
        ativo: null == ativo
            ? _value.ativo
            : ativo // ignore: cast_nullable_to_non_nullable
                  as bool,
        criadoEm: null == criadoEm
            ? _value.criadoEm
            : criadoEm // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        oficinas: null == oficinas
            ? _value._oficinas
            : oficinas // ignore: cast_nullable_to_non_nullable
                  as List<OficinaRef>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FuncionarioImpl implements _Funcionario {
  const _$FuncionarioImpl({
    required this.id,
    required this.userId,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.tipoRemuneracao,
    this.salario,
    this.porcentagem,
    this.telefone,
    required this.ativo,
    required this.criadoEm,
    final List<OficinaRef> oficinas = const [],
  }) : _oficinas = oficinas;

  factory _$FuncionarioImpl.fromJson(Map<String, dynamic> json) =>
      _$$FuncionarioImplFromJson(json);

  @override
  final int id;
  @override
  final int userId;
  @override
  final String nome;
  @override
  final String email;
  @override
  final String cargo;
  @override
  final String tipoRemuneracao;
  @override
  final double? salario;
  @override
  final double? porcentagem;
  @override
  final String? telefone;
  @override
  final bool ativo;
  @override
  final DateTime criadoEm;
  final List<OficinaRef> _oficinas;
  @override
  @JsonKey()
  List<OficinaRef> get oficinas {
    if (_oficinas is EqualUnmodifiableListView) return _oficinas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_oficinas);
  }

  @override
  String toString() {
    return 'Funcionario(id: $id, userId: $userId, nome: $nome, email: $email, cargo: $cargo, tipoRemuneracao: $tipoRemuneracao, salario: $salario, porcentagem: $porcentagem, telefone: $telefone, ativo: $ativo, criadoEm: $criadoEm, oficinas: $oficinas)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FuncionarioImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.nome, nome) || other.nome == nome) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.cargo, cargo) || other.cargo == cargo) &&
            (identical(other.tipoRemuneracao, tipoRemuneracao) ||
                other.tipoRemuneracao == tipoRemuneracao) &&
            (identical(other.salario, salario) || other.salario == salario) &&
            (identical(other.porcentagem, porcentagem) ||
                other.porcentagem == porcentagem) &&
            (identical(other.telefone, telefone) ||
                other.telefone == telefone) &&
            (identical(other.ativo, ativo) || other.ativo == ativo) &&
            (identical(other.criadoEm, criadoEm) ||
                other.criadoEm == criadoEm) &&
            const DeepCollectionEquality().equals(other._oficinas, _oficinas));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    nome,
    email,
    cargo,
    tipoRemuneracao,
    salario,
    porcentagem,
    telefone,
    ativo,
    criadoEm,
    const DeepCollectionEquality().hash(_oficinas),
  );

  /// Create a copy of Funcionario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FuncionarioImplCopyWith<_$FuncionarioImpl> get copyWith =>
      __$$FuncionarioImplCopyWithImpl<_$FuncionarioImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FuncionarioImplToJson(this);
  }
}

abstract class _Funcionario implements Funcionario {
  const factory _Funcionario({
    required final int id,
    required final int userId,
    required final String nome,
    required final String email,
    required final String cargo,
    required final String tipoRemuneracao,
    final double? salario,
    final double? porcentagem,
    final String? telefone,
    required final bool ativo,
    required final DateTime criadoEm,
    final List<OficinaRef> oficinas,
  }) = _$FuncionarioImpl;

  factory _Funcionario.fromJson(Map<String, dynamic> json) =
      _$FuncionarioImpl.fromJson;

  @override
  int get id;
  @override
  int get userId;
  @override
  String get nome;
  @override
  String get email;
  @override
  String get cargo;
  @override
  String get tipoRemuneracao;
  @override
  double? get salario;
  @override
  double? get porcentagem;
  @override
  String? get telefone;
  @override
  bool get ativo;
  @override
  DateTime get criadoEm;
  @override
  List<OficinaRef> get oficinas;

  /// Create a copy of Funcionario
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FuncionarioImplCopyWith<_$FuncionarioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OficinaRef _$OficinaRefFromJson(Map<String, dynamic> json) {
  return _OficinaRef.fromJson(json);
}

/// @nodoc
mixin _$OficinaRef {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;

  /// Serializes this OficinaRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OficinaRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OficinaRefCopyWith<OficinaRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OficinaRefCopyWith<$Res> {
  factory $OficinaRefCopyWith(
    OficinaRef value,
    $Res Function(OficinaRef) then,
  ) = _$OficinaRefCopyWithImpl<$Res, OficinaRef>;
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class _$OficinaRefCopyWithImpl<$Res, $Val extends OficinaRef>
    implements $OficinaRefCopyWith<$Res> {
  _$OficinaRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OficinaRef
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
abstract class _$$OficinaRefImplCopyWith<$Res>
    implements $OficinaRefCopyWith<$Res> {
  factory _$$OficinaRefImplCopyWith(
    _$OficinaRefImpl value,
    $Res Function(_$OficinaRefImpl) then,
  ) = __$$OficinaRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class __$$OficinaRefImplCopyWithImpl<$Res>
    extends _$OficinaRefCopyWithImpl<$Res, _$OficinaRefImpl>
    implements _$$OficinaRefImplCopyWith<$Res> {
  __$$OficinaRefImplCopyWithImpl(
    _$OficinaRefImpl _value,
    $Res Function(_$OficinaRefImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OficinaRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? nome = null}) {
    return _then(
      _$OficinaRefImpl(
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
class _$OficinaRefImpl implements _OficinaRef {
  const _$OficinaRefImpl({required this.id, required this.nome});

  factory _$OficinaRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$OficinaRefImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;

  @override
  String toString() {
    return 'OficinaRef(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OficinaRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nome);

  /// Create a copy of OficinaRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OficinaRefImplCopyWith<_$OficinaRefImpl> get copyWith =>
      __$$OficinaRefImplCopyWithImpl<_$OficinaRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OficinaRefImplToJson(this);
  }
}

abstract class _OficinaRef implements OficinaRef {
  const factory _OficinaRef({
    required final int id,
    required final String nome,
  }) = _$OficinaRefImpl;

  factory _OficinaRef.fromJson(Map<String, dynamic> json) =
      _$OficinaRefImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;

  /// Create a copy of OficinaRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OficinaRefImplCopyWith<_$OficinaRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
