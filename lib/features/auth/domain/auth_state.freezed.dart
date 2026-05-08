// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GrupoItem _$GrupoItemFromJson(Map<String, dynamic> json) {
  return _GrupoItem.fromJson(json);
}

/// @nodoc
mixin _$GrupoItem {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;

  /// Serializes this GrupoItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GrupoItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GrupoItemCopyWith<GrupoItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GrupoItemCopyWith<$Res> {
  factory $GrupoItemCopyWith(GrupoItem value, $Res Function(GrupoItem) then) =
      _$GrupoItemCopyWithImpl<$Res, GrupoItem>;
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class _$GrupoItemCopyWithImpl<$Res, $Val extends GrupoItem>
    implements $GrupoItemCopyWith<$Res> {
  _$GrupoItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GrupoItem
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
abstract class _$$GrupoItemImplCopyWith<$Res>
    implements $GrupoItemCopyWith<$Res> {
  factory _$$GrupoItemImplCopyWith(
    _$GrupoItemImpl value,
    $Res Function(_$GrupoItemImpl) then,
  ) = __$$GrupoItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class __$$GrupoItemImplCopyWithImpl<$Res>
    extends _$GrupoItemCopyWithImpl<$Res, _$GrupoItemImpl>
    implements _$$GrupoItemImplCopyWith<$Res> {
  __$$GrupoItemImplCopyWithImpl(
    _$GrupoItemImpl _value,
    $Res Function(_$GrupoItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GrupoItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? nome = null}) {
    return _then(
      _$GrupoItemImpl(
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
class _$GrupoItemImpl implements _GrupoItem {
  const _$GrupoItemImpl({required this.id, required this.nome});

  factory _$GrupoItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GrupoItemImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;

  @override
  String toString() {
    return 'GrupoItem(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GrupoItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nome);

  /// Create a copy of GrupoItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GrupoItemImplCopyWith<_$GrupoItemImpl> get copyWith =>
      __$$GrupoItemImplCopyWithImpl<_$GrupoItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GrupoItemImplToJson(this);
  }
}

abstract class _GrupoItem implements GrupoItem {
  const factory _GrupoItem({
    required final int id,
    required final String nome,
  }) = _$GrupoItemImpl;

  factory _GrupoItem.fromJson(Map<String, dynamic> json) =
      _$GrupoItemImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;

  /// Create a copy of GrupoItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GrupoItemImplCopyWith<_$GrupoItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AuthState {
  String? get token => throw _privateConstructorUsedError;
  int? get userId => throw _privateConstructorUsedError;
  int? get grupoOficinaId => throw _privateConstructorUsedError;
  bool get isAuthenticated => throw _privateConstructorUsedError;
  bool get pendingGroupSelection => throw _privateConstructorUsedError;
  List<GrupoItem> get availableGroups => throw _privateConstructorUsedError;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthStateCopyWith<AuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
  @useResult
  $Res call({
    String? token,
    int? userId,
    int? grupoOficinaId,
    bool isAuthenticated,
    bool pendingGroupSelection,
    List<GrupoItem> availableGroups,
  });
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = freezed,
    Object? userId = freezed,
    Object? grupoOficinaId = freezed,
    Object? isAuthenticated = null,
    Object? pendingGroupSelection = null,
    Object? availableGroups = null,
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
            isAuthenticated: null == isAuthenticated
                ? _value.isAuthenticated
                : isAuthenticated // ignore: cast_nullable_to_non_nullable
                      as bool,
            pendingGroupSelection: null == pendingGroupSelection
                ? _value.pendingGroupSelection
                : pendingGroupSelection // ignore: cast_nullable_to_non_nullable
                      as bool,
            availableGroups: null == availableGroups
                ? _value.availableGroups
                : availableGroups // ignore: cast_nullable_to_non_nullable
                      as List<GrupoItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthStateImplCopyWith<$Res>
    implements $AuthStateCopyWith<$Res> {
  factory _$$AuthStateImplCopyWith(
    _$AuthStateImpl value,
    $Res Function(_$AuthStateImpl) then,
  ) = __$$AuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? token,
    int? userId,
    int? grupoOficinaId,
    bool isAuthenticated,
    bool pendingGroupSelection,
    List<GrupoItem> availableGroups,
  });
}

/// @nodoc
class __$$AuthStateImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AuthStateImpl>
    implements _$$AuthStateImplCopyWith<$Res> {
  __$$AuthStateImplCopyWithImpl(
    _$AuthStateImpl _value,
    $Res Function(_$AuthStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? token = freezed,
    Object? userId = freezed,
    Object? grupoOficinaId = freezed,
    Object? isAuthenticated = null,
    Object? pendingGroupSelection = null,
    Object? availableGroups = null,
  }) {
    return _then(
      _$AuthStateImpl(
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
        isAuthenticated: null == isAuthenticated
            ? _value.isAuthenticated
            : isAuthenticated // ignore: cast_nullable_to_non_nullable
                  as bool,
        pendingGroupSelection: null == pendingGroupSelection
            ? _value.pendingGroupSelection
            : pendingGroupSelection // ignore: cast_nullable_to_non_nullable
                  as bool,
        availableGroups: null == availableGroups
            ? _value._availableGroups
            : availableGroups // ignore: cast_nullable_to_non_nullable
                  as List<GrupoItem>,
      ),
    );
  }
}

/// @nodoc

class _$AuthStateImpl implements _AuthState {
  const _$AuthStateImpl({
    this.token,
    this.userId,
    this.grupoOficinaId,
    this.isAuthenticated = false,
    this.pendingGroupSelection = false,
    final List<GrupoItem> availableGroups = const [],
  }) : _availableGroups = availableGroups;

  @override
  final String? token;
  @override
  final int? userId;
  @override
  final int? grupoOficinaId;
  @override
  @JsonKey()
  final bool isAuthenticated;
  @override
  @JsonKey()
  final bool pendingGroupSelection;
  final List<GrupoItem> _availableGroups;
  @override
  @JsonKey()
  List<GrupoItem> get availableGroups {
    if (_availableGroups is EqualUnmodifiableListView) return _availableGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableGroups);
  }

  @override
  String toString() {
    return 'AuthState(token: $token, userId: $userId, grupoOficinaId: $grupoOficinaId, isAuthenticated: $isAuthenticated, pendingGroupSelection: $pendingGroupSelection, availableGroups: $availableGroups)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthStateImpl &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.grupoOficinaId, grupoOficinaId) ||
                other.grupoOficinaId == grupoOficinaId) &&
            (identical(other.isAuthenticated, isAuthenticated) ||
                other.isAuthenticated == isAuthenticated) &&
            (identical(other.pendingGroupSelection, pendingGroupSelection) ||
                other.pendingGroupSelection == pendingGroupSelection) &&
            const DeepCollectionEquality().equals(
              other._availableGroups,
              _availableGroups,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    token,
    userId,
    grupoOficinaId,
    isAuthenticated,
    pendingGroupSelection,
    const DeepCollectionEquality().hash(_availableGroups),
  );

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      __$$AuthStateImplCopyWithImpl<_$AuthStateImpl>(this, _$identity);
}

abstract class _AuthState implements AuthState {
  const factory _AuthState({
    final String? token,
    final int? userId,
    final int? grupoOficinaId,
    final bool isAuthenticated,
    final bool pendingGroupSelection,
    final List<GrupoItem> availableGroups,
  }) = _$AuthStateImpl;

  @override
  String? get token;
  @override
  int? get userId;
  @override
  int? get grupoOficinaId;
  @override
  bool get isAuthenticated;
  @override
  bool get pendingGroupSelection;
  @override
  List<GrupoItem> get availableGroups;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
