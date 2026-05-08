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
  List<GrupoItem>? get selecioneGrupo => throw _privateConstructorUsedError;

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
    List<GrupoItem>? selecioneGrupo,
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
    Object? selecioneGrupo = freezed,
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
            selecioneGrupo: freezed == selecioneGrupo
                ? _value.selecioneGrupo
                : selecioneGrupo // ignore: cast_nullable_to_non_nullable
                      as List<GrupoItem>?,
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
    List<GrupoItem>? selecioneGrupo,
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
    Object? selecioneGrupo = freezed,
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
        selecioneGrupo: freezed == selecioneGrupo
            ? _value._selecioneGrupo
            : selecioneGrupo // ignore: cast_nullable_to_non_nullable
                  as List<GrupoItem>?,
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
    final List<GrupoItem>? selecioneGrupo,
  }) : _selecioneGrupo = selecioneGrupo;

  factory _$LoginResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginResponseImplFromJson(json);

  @override
  final String? token;
  @override
  final int? userId;
  @override
  final int? grupoOficinaId;
  final List<GrupoItem>? _selecioneGrupo;
  @override
  List<GrupoItem>? get selecioneGrupo {
    final value = _selecioneGrupo;
    if (value == null) return null;
    if (_selecioneGrupo is EqualUnmodifiableListView) return _selecioneGrupo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'LoginResponse(token: $token, userId: $userId, grupoOficinaId: $grupoOficinaId, selecioneGrupo: $selecioneGrupo)';
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
            const DeepCollectionEquality().equals(
              other._selecioneGrupo,
              _selecioneGrupo,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    token,
    userId,
    grupoOficinaId,
    const DeepCollectionEquality().hash(_selecioneGrupo),
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
    final List<GrupoItem>? selecioneGrupo,
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
  List<GrupoItem>? get selecioneGrupo;

  /// Create a copy of LoginResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginResponseImplCopyWith<_$LoginResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SelectGroupResponse _$SelectGroupResponseFromJson(Map<String, dynamic> json) {
  return _SelectGroupResponse.fromJson(json);
}

/// @nodoc
mixin _$SelectGroupResponse {
  String get token => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;
  int get grupoOficinaId => throw _privateConstructorUsedError;

  /// Serializes this SelectGroupResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SelectGroupResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SelectGroupResponseCopyWith<SelectGroupResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectGroupResponseCopyWith<$Res> {
  factory $SelectGroupResponseCopyWith(
    SelectGroupResponse value,
    $Res Function(SelectGroupResponse) then,
  ) = _$SelectGroupResponseCopyWithImpl<$Res, SelectGroupResponse>;
  @useResult
  $Res call({String token, int userId, int grupoOficinaId});
}

/// @nodoc
class _$SelectGroupResponseCopyWithImpl<$Res, $Val extends SelectGroupResponse>
    implements $SelectGroupResponseCopyWith<$Res> {
  _$SelectGroupResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SelectGroupResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? userId = null,
    Object? grupoOficinaId = null,
  }) {
    return _then(
      _value.copyWith(
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$SelectGroupResponseImplCopyWith<$Res>
    implements $SelectGroupResponseCopyWith<$Res> {
  factory _$$SelectGroupResponseImplCopyWith(
    _$SelectGroupResponseImpl value,
    $Res Function(_$SelectGroupResponseImpl) then,
  ) = __$$SelectGroupResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String token, int userId, int grupoOficinaId});
}

/// @nodoc
class __$$SelectGroupResponseImplCopyWithImpl<$Res>
    extends _$SelectGroupResponseCopyWithImpl<$Res, _$SelectGroupResponseImpl>
    implements _$$SelectGroupResponseImplCopyWith<$Res> {
  __$$SelectGroupResponseImplCopyWithImpl(
    _$SelectGroupResponseImpl _value,
    $Res Function(_$SelectGroupResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SelectGroupResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = null,
    Object? userId = null,
    Object? grupoOficinaId = null,
  }) {
    return _then(
      _$SelectGroupResponseImpl(
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$SelectGroupResponseImpl implements _SelectGroupResponse {
  const _$SelectGroupResponseImpl({
    required this.token,
    required this.userId,
    required this.grupoOficinaId,
  });

  factory _$SelectGroupResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelectGroupResponseImplFromJson(json);

  @override
  final String token;
  @override
  final int userId;
  @override
  final int grupoOficinaId;

  @override
  String toString() {
    return 'SelectGroupResponse(token: $token, userId: $userId, grupoOficinaId: $grupoOficinaId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectGroupResponseImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.grupoOficinaId, grupoOficinaId) ||
                other.grupoOficinaId == grupoOficinaId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, token, userId, grupoOficinaId);

  /// Create a copy of SelectGroupResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectGroupResponseImplCopyWith<_$SelectGroupResponseImpl> get copyWith =>
      __$$SelectGroupResponseImplCopyWithImpl<_$SelectGroupResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SelectGroupResponseImplToJson(this);
  }
}

abstract class _SelectGroupResponse implements SelectGroupResponse {
  const factory _SelectGroupResponse({
    required final String token,
    required final int userId,
    required final int grupoOficinaId,
  }) = _$SelectGroupResponseImpl;

  factory _SelectGroupResponse.fromJson(Map<String, dynamic> json) =
      _$SelectGroupResponseImpl.fromJson;

  @override
  String get token;
  @override
  int get userId;
  @override
  int get grupoOficinaId;

  /// Create a copy of SelectGroupResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SelectGroupResponseImplCopyWith<_$SelectGroupResponseImpl> get copyWith =>
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
