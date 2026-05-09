// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) {
  return _LoginResponse.fromJson(json);
}

/// @nodoc
mixin _$LoginResponse {
  String? get token => throw _privateConstructorUsedError;
  int? get userId => throw _privateConstructorUsedError;
  int? get grupoOficinaId => throw _privateConstructorUsedError;
  int? get oficinaId => throw _privateConstructorUsedError;
  List<GrupoItem>? get selecioneGrupo => throw _privateConstructorUsedError;
  List<OficinaItem>? get selecioneOficina => throw _privateConstructorUsedError;
  bool get precisaTrocarSenha => throw _privateConstructorUsedError;

  /// Serializes this LoginResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginResponseCopyWith<LoginResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginResponseCopyWith<$Res> {
  factory $LoginResponseCopyWith(
    LoginResponse value,
    $Res Function(LoginResponse) then,
  ) = _$LoginResponseCopyWithImpl<$Res, LoginResponse>;
  @useResult
  $Res call({
    String? token,
    int? userId,
    int? grupoOficinaId,
    int? oficinaId,
    List<GrupoItem>? selecioneGrupo,
    List<OficinaItem>? selecioneOficina,
    bool precisaTrocarSenha,
  });
}

/// @nodoc
class _$LoginResponseCopyWithImpl<$Res, $Val extends LoginResponse>
    implements $LoginResponseCopyWith<$Res> {
  _$LoginResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = freezed,
    Object? userId = freezed,
    Object? grupoOficinaId = freezed,
    Object? oficinaId = freezed,
    Object? selecioneGrupo = freezed,
    Object? selecioneOficina = freezed,
    Object? precisaTrocarSenha = null,
  }) {
    return _then(
      _value.copyWith(
            token: freezed == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String?,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int?,
            grupoOficinaId: freezed == grupoOficinaId
                ? _value.grupoOficinaId
                : grupoOficinaId // ignore: cast_nullable_to_non_nullable
                      as int?,
            oficinaId: freezed == oficinaId
                ? _value.oficinaId
                : oficinaId // ignore: cast_nullable_to_non_nullable
                      as int?,
            selecioneGrupo: freezed == selecioneGrupo
                ? _value.selecioneGrupo
                : selecioneGrupo // ignore: cast_nullable_to_non_nullable
                      as List<GrupoItem>?,
            selecioneOficina: freezed == selecioneOficina
                ? _value.selecioneOficina
                : selecioneOficina // ignore: cast_nullable_to_non_nullable
                      as List<OficinaItem>?,
            precisaTrocarSenha: null == precisaTrocarSenha
                ? _value.precisaTrocarSenha
                : precisaTrocarSenha // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginResponseImplCopyWith<$Res>
    implements $LoginResponseCopyWith<$Res> {
  factory _$$LoginResponseImplCopyWith(
    _$LoginResponseImpl value,
    $Res Function(_$LoginResponseImpl) then,
  ) = __$$LoginResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? token,
    int? userId,
    int? grupoOficinaId,
    int? oficinaId,
    List<GrupoItem>? selecioneGrupo,
    List<OficinaItem>? selecioneOficina,
    bool precisaTrocarSenha,
  });
}

/// @nodoc
class __$$LoginResponseImplCopyWithImpl<$Res>
    extends _$LoginResponseCopyWithImpl<$Res, _$LoginResponseImpl>
    implements _$$LoginResponseImplCopyWith<$Res> {
  __$$LoginResponseImplCopyWithImpl(
    _$LoginResponseImpl _value,
    $Res Function(_$LoginResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = freezed,
    Object? userId = freezed,
    Object? grupoOficinaId = freezed,
    Object? oficinaId = freezed,
    Object? selecioneGrupo = freezed,
    Object? selecioneOficina = freezed,
    Object? precisaTrocarSenha = null,
  }) {
    return _then(
      _$LoginResponseImpl(
        token: freezed == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int?,
        grupoOficinaId: freezed == grupoOficinaId
            ? _value.grupoOficinaId
            : grupoOficinaId // ignore: cast_nullable_to_non_nullable
                  as int?,
        oficinaId: freezed == oficinaId
            ? _value.oficinaId
            : oficinaId // ignore: cast_nullable_to_non_nullable
                  as int?,
        selecioneGrupo: freezed == selecioneGrupo
            ? _value._selecioneGrupo
            : selecioneGrupo // ignore: cast_nullable_to_non_nullable
                  as List<GrupoItem>?,
        selecioneOficina: freezed == selecioneOficina
            ? _value._selecioneOficina
            : selecioneOficina // ignore: cast_nullable_to_non_nullable
                  as List<OficinaItem>?,
        precisaTrocarSenha: null == precisaTrocarSenha
            ? _value.precisaTrocarSenha
            : precisaTrocarSenha // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginResponseImpl implements _LoginResponse {
  const _$LoginResponseImpl({
    this.token,
    this.userId,
    this.grupoOficinaId,
    this.oficinaId,
    final List<GrupoItem>? selecioneGrupo,
    final List<OficinaItem>? selecioneOficina,
    this.precisaTrocarSenha = false,
  }) : _selecioneGrupo = selecioneGrupo,
       _selecioneOficina = selecioneOficina;

  factory _$LoginResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginResponseImplFromJson(json);

  @override
  final String? token;
  @override
  final int? userId;
  @override
  final int? grupoOficinaId;
  @override
  final int? oficinaId;
  final List<GrupoItem>? _selecioneGrupo;
  @override
  List<GrupoItem>? get selecioneGrupo {
    final value = _selecioneGrupo;
    if (value == null) return null;
    if (_selecioneGrupo is EqualUnmodifiableListView) return _selecioneGrupo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<OficinaItem>? _selecioneOficina;
  @override
  List<OficinaItem>? get selecioneOficina {
    final value = _selecioneOficina;
    if (value == null) return null;
    if (_selecioneOficina is EqualUnmodifiableListView)
      return _selecioneOficina;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool precisaTrocarSenha;

  @override
  String toString() {
    return 'LoginResponse(token: $token, userId: $userId, grupoOficinaId: $grupoOficinaId, oficinaId: $oficinaId, selecioneGrupo: $selecioneGrupo, selecioneOficina: $selecioneOficina, precisaTrocarSenha: $precisaTrocarSenha)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginResponseImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.grupoOficinaId, grupoOficinaId) ||
                other.grupoOficinaId == grupoOficinaId) &&
            (identical(other.oficinaId, oficinaId) ||
                other.oficinaId == oficinaId) &&
            const DeepCollectionEquality().equals(
              other._selecioneGrupo,
              _selecioneGrupo,
            ) &&
            const DeepCollectionEquality().equals(
              other._selecioneOficina,
              _selecioneOficina,
            ) &&
            (identical(other.precisaTrocarSenha, precisaTrocarSenha) ||
                other.precisaTrocarSenha == precisaTrocarSenha));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    token,
    userId,
    grupoOficinaId,
    oficinaId,
    const DeepCollectionEquality().hash(_selecioneGrupo),
    const DeepCollectionEquality().hash(_selecioneOficina),
    precisaTrocarSenha,
  );

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginResponseImplCopyWith<_$LoginResponseImpl> get copyWith =>
      __$$LoginResponseImplCopyWithImpl<_$LoginResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginResponseImplToJson(this);
  }
}

abstract class _LoginResponse implements LoginResponse {
  const factory _LoginResponse({
    final String? token,
    final int? userId,
    final int? grupoOficinaId,
    final int? oficinaId,
    final List<GrupoItem>? selecioneGrupo,
    final List<OficinaItem>? selecioneOficina,
    final bool precisaTrocarSenha,
  }) = _$LoginResponseImpl;

  factory _LoginResponse.fromJson(Map<String, dynamic> json) =
      _$LoginResponseImpl.fromJson;

  @override
  String? get token;
  @override
  int? get userId;
  @override
  int? get grupoOficinaId;
  @override
  int? get oficinaId;
  @override
  List<GrupoItem>? get selecioneGrupo;
  @override
  List<OficinaItem>? get selecioneOficina;
  @override
  bool get precisaTrocarSenha;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginResponseImplCopyWith<_$LoginResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) {
  return _LoginRequest.fromJson(json);
}

/// @nodoc
mixin _$LoginRequest {
  String get email => throw _privateConstructorUsedError;
  String get senha => throw _privateConstructorUsedError;

  /// Serializes this LoginRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginRequestCopyWith<LoginRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginRequestCopyWith<$Res> {
  factory $LoginRequestCopyWith(
    LoginRequest value,
    $Res Function(LoginRequest) then,
  ) = _$LoginRequestCopyWithImpl<$Res, LoginRequest>;
  @useResult
  $Res call({String email, String senha});
}

/// @nodoc
class _$LoginRequestCopyWithImpl<$Res, $Val extends LoginRequest>
    implements $LoginRequestCopyWith<$Res> {
  _$LoginRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? senha = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            senha: null == senha
                ? _value.senha
                : senha // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginRequestImplCopyWith<$Res>
    implements $LoginRequestCopyWith<$Res> {
  factory _$$LoginRequestImplCopyWith(
    _$LoginRequestImpl value,
    $Res Function(_$LoginRequestImpl) then,
  ) = __$$LoginRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email, String senha});
}

/// @nodoc
class __$$LoginRequestImplCopyWithImpl<$Res>
    extends _$LoginRequestCopyWithImpl<$Res, _$LoginRequestImpl>
    implements _$$LoginRequestImplCopyWith<$Res> {
  __$$LoginRequestImplCopyWithImpl(
    _$LoginRequestImpl _value,
    $Res Function(_$LoginRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? senha = null}) {
    return _then(
      _$LoginRequestImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        senha: null == senha
            ? _value.senha
            : senha // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginRequestImpl implements _LoginRequest {
  const _$LoginRequestImpl({required this.email, required this.senha});

  factory _$LoginRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginRequestImplFromJson(json);

  @override
  final String email;
  @override
  final String senha;

  @override
  String toString() {
    return 'LoginRequest(email: $email, senha: $senha)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginRequestImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.senha, senha) || other.senha == senha));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, senha);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      __$$LoginRequestImplCopyWithImpl<_$LoginRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginRequestImplToJson(this);
  }
}

abstract class _LoginRequest implements LoginRequest {
  const factory _LoginRequest({
    required final String email,
    required final String senha,
  }) = _$LoginRequestImpl;

  factory _LoginRequest.fromJson(Map<String, dynamic> json) =
      _$LoginRequestImpl.fromJson;

  @override
  String get email;
  @override
  String get senha;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SelectGroupRequest _$SelectGroupRequestFromJson(Map<String, dynamic> json) {
  return _SelectGroupRequest.fromJson(json);
}

/// @nodoc
mixin _$SelectGroupRequest {
  int get userId => throw _privateConstructorUsedError;
  int get grupoOficinaId => throw _privateConstructorUsedError;

  /// Serializes this SelectGroupRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SelectGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SelectGroupRequestCopyWith<SelectGroupRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectGroupRequestCopyWith<$Res> {
  factory $SelectGroupRequestCopyWith(
    SelectGroupRequest value,
    $Res Function(SelectGroupRequest) then,
  ) = _$SelectGroupRequestCopyWithImpl<$Res, SelectGroupRequest>;
  @useResult
  $Res call({int userId, int grupoOficinaId});
}

/// @nodoc
class _$SelectGroupRequestCopyWithImpl<$Res, $Val extends SelectGroupRequest>
    implements $SelectGroupRequestCopyWith<$Res> {
  _$SelectGroupRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SelectGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? grupoOficinaId = null}) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            grupoOficinaId: null == grupoOficinaId
                ? _value.grupoOficinaId
                : grupoOficinaId // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SelectGroupRequestImplCopyWith<$Res>
    implements $SelectGroupRequestCopyWith<$Res> {
  factory _$$SelectGroupRequestImplCopyWith(
    _$SelectGroupRequestImpl value,
    $Res Function(_$SelectGroupRequestImpl) then,
  ) = __$$SelectGroupRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int userId, int grupoOficinaId});
}

/// @nodoc
class __$$SelectGroupRequestImplCopyWithImpl<$Res>
    extends _$SelectGroupRequestCopyWithImpl<$Res, _$SelectGroupRequestImpl>
    implements _$$SelectGroupRequestImplCopyWith<$Res> {
  __$$SelectGroupRequestImplCopyWithImpl(
    _$SelectGroupRequestImpl _value,
    $Res Function(_$SelectGroupRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SelectGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? grupoOficinaId = null}) {
    return _then(
      _$SelectGroupRequestImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        grupoOficinaId: null == grupoOficinaId
            ? _value.grupoOficinaId
            : grupoOficinaId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SelectGroupRequestImpl implements _SelectGroupRequest {
  const _$SelectGroupRequestImpl({
    required this.userId,
    required this.grupoOficinaId,
  });

  factory _$SelectGroupRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelectGroupRequestImplFromJson(json);

  @override
  final int userId;
  @override
  final int grupoOficinaId;

  @override
  String toString() {
    return 'SelectGroupRequest(userId: $userId, grupoOficinaId: $grupoOficinaId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectGroupRequestImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.grupoOficinaId, grupoOficinaId) ||
                other.grupoOficinaId == grupoOficinaId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, grupoOficinaId);

  /// Create a copy of SelectGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectGroupRequestImplCopyWith<_$SelectGroupRequestImpl> get copyWith =>
      __$$SelectGroupRequestImplCopyWithImpl<_$SelectGroupRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SelectGroupRequestImplToJson(this);
  }
}

abstract class _SelectGroupRequest implements SelectGroupRequest {
  const factory _SelectGroupRequest({
    required final int userId,
    required final int grupoOficinaId,
  }) = _$SelectGroupRequestImpl;

  factory _SelectGroupRequest.fromJson(Map<String, dynamic> json) =
      _$SelectGroupRequestImpl.fromJson;

  @override
  int get userId;
  @override
  int get grupoOficinaId;

  /// Create a copy of SelectGroupRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SelectGroupRequestImplCopyWith<_$SelectGroupRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SelectOficinaRequest _$SelectOficinaRequestFromJson(Map<String, dynamic> json) {
  return _SelectOficinaRequest.fromJson(json);
}

/// @nodoc
mixin _$SelectOficinaRequest {
  int get oficinaId => throw _privateConstructorUsedError;

  /// Serializes this SelectOficinaRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SelectOficinaRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SelectOficinaRequestCopyWith<SelectOficinaRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectOficinaRequestCopyWith<$Res> {
  factory $SelectOficinaRequestCopyWith(
    SelectOficinaRequest value,
    $Res Function(SelectOficinaRequest) then,
  ) = _$SelectOficinaRequestCopyWithImpl<$Res, SelectOficinaRequest>;
  @useResult
  $Res call({int oficinaId});
}

/// @nodoc
class _$SelectOficinaRequestCopyWithImpl<
  $Res,
  $Val extends SelectOficinaRequest
>
    implements $SelectOficinaRequestCopyWith<$Res> {
  _$SelectOficinaRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SelectOficinaRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? oficinaId = null}) {
    return _then(
      _value.copyWith(
            oficinaId: null == oficinaId
                ? _value.oficinaId
                : oficinaId // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SelectOficinaRequestImplCopyWith<$Res>
    implements $SelectOficinaRequestCopyWith<$Res> {
  factory _$$SelectOficinaRequestImplCopyWith(
    _$SelectOficinaRequestImpl value,
    $Res Function(_$SelectOficinaRequestImpl) then,
  ) = __$$SelectOficinaRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int oficinaId});
}

/// @nodoc
class __$$SelectOficinaRequestImplCopyWithImpl<$Res>
    extends _$SelectOficinaRequestCopyWithImpl<$Res, _$SelectOficinaRequestImpl>
    implements _$$SelectOficinaRequestImplCopyWith<$Res> {
  __$$SelectOficinaRequestImplCopyWithImpl(
    _$SelectOficinaRequestImpl _value,
    $Res Function(_$SelectOficinaRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SelectOficinaRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? oficinaId = null}) {
    return _then(
      _$SelectOficinaRequestImpl(
        oficinaId: null == oficinaId
            ? _value.oficinaId
            : oficinaId // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SelectOficinaRequestImpl implements _SelectOficinaRequest {
  const _$SelectOficinaRequestImpl({required this.oficinaId});

  factory _$SelectOficinaRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelectOficinaRequestImplFromJson(json);

  @override
  final int oficinaId;

  @override
  String toString() {
    return 'SelectOficinaRequest(oficinaId: $oficinaId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectOficinaRequestImpl &&
            (identical(other.oficinaId, oficinaId) ||
                other.oficinaId == oficinaId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, oficinaId);

  /// Create a copy of SelectOficinaRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectOficinaRequestImplCopyWith<_$SelectOficinaRequestImpl>
  get copyWith =>
      __$$SelectOficinaRequestImplCopyWithImpl<_$SelectOficinaRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SelectOficinaRequestImplToJson(this);
  }
}

abstract class _SelectOficinaRequest implements SelectOficinaRequest {
  const factory _SelectOficinaRequest({required final int oficinaId}) =
      _$SelectOficinaRequestImpl;

  factory _SelectOficinaRequest.fromJson(Map<String, dynamic> json) =
      _$SelectOficinaRequestImpl.fromJson;

  @override
  int get oficinaId;

  /// Create a copy of SelectOficinaRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SelectOficinaRequestImplCopyWith<_$SelectOficinaRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}
