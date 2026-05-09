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

OficinaItem _$OficinaItemFromJson(Map<String, dynamic> json) {
  return _OficinaItem.fromJson(json);
}

/// @nodoc
mixin _$OficinaItem {
  int get id => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;

  /// Serializes this OficinaItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OficinaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OficinaItemCopyWith<OficinaItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OficinaItemCopyWith<$Res> {
  factory $OficinaItemCopyWith(
    OficinaItem value,
    $Res Function(OficinaItem) then,
  ) = _$OficinaItemCopyWithImpl<$Res, OficinaItem>;
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class _$OficinaItemCopyWithImpl<$Res, $Val extends OficinaItem>
    implements $OficinaItemCopyWith<$Res> {
  _$OficinaItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OficinaItem
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
abstract class _$$OficinaItemImplCopyWith<$Res>
    implements $OficinaItemCopyWith<$Res> {
  factory _$$OficinaItemImplCopyWith(
    _$OficinaItemImpl value,
    $Res Function(_$OficinaItemImpl) then,
  ) = __$$OficinaItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String nome});
}

/// @nodoc
class __$$OficinaItemImplCopyWithImpl<$Res>
    extends _$OficinaItemCopyWithImpl<$Res, _$OficinaItemImpl>
    implements _$$OficinaItemImplCopyWith<$Res> {
  __$$OficinaItemImplCopyWithImpl(
    _$OficinaItemImpl _value,
    $Res Function(_$OficinaItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OficinaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? nome = null}) {
    return _then(
      _$OficinaItemImpl(
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
class _$OficinaItemImpl implements _OficinaItem {
  const _$OficinaItemImpl({required this.id, required this.nome});

  factory _$OficinaItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OficinaItemImplFromJson(json);

  @override
  final int id;
  @override
  final String nome;

  @override
  String toString() {
    return 'OficinaItem(id: $id, nome: $nome)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OficinaItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nome, nome) || other.nome == nome));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nome);

  /// Create a copy of OficinaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OficinaItemImplCopyWith<_$OficinaItemImpl> get copyWith =>
      __$$OficinaItemImplCopyWithImpl<_$OficinaItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OficinaItemImplToJson(this);
  }
}

abstract class _OficinaItem implements OficinaItem {
  const factory _OficinaItem({
    required final int id,
    required final String nome,
  }) = _$OficinaItemImpl;

  factory _OficinaItem.fromJson(Map<String, dynamic> json) =
      _$OficinaItemImpl.fromJson;

  @override
  int get id;
  @override
  String get nome;

  /// Create a copy of OficinaItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OficinaItemImplCopyWith<_$OficinaItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AuthState {
  String? get token => throw _privateConstructorUsedError;
  int? get userId => throw _privateConstructorUsedError;
  int? get grupoOficinaId => throw _privateConstructorUsedError;
  int? get oficinaId => throw _privateConstructorUsedError;
  bool get isAuthenticated => throw _privateConstructorUsedError;
  bool get pendingGroupSelection => throw _privateConstructorUsedError;
  bool get pendingOficinaSelection => throw _privateConstructorUsedError;
  bool get pendingPasswordChange => throw _privateConstructorUsedError;
  List<GrupoItem> get availableGroups => throw _privateConstructorUsedError;
  List<OficinaItem> get availableOficinas => throw _privateConstructorUsedError;

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
    int? oficinaId,
    bool isAuthenticated,
    bool pendingGroupSelection,
    bool pendingOficinaSelection,
    bool pendingPasswordChange,
    List<GrupoItem> availableGroups,
    List<OficinaItem> availableOficinas,
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
    Object? oficinaId = freezed,
    Object? isAuthenticated = null,
    Object? pendingGroupSelection = null,
    Object? pendingOficinaSelection = null,
    Object? pendingPasswordChange = null,
    Object? availableGroups = null,
    Object? availableOficinas = null,
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
            isAuthenticated: null == isAuthenticated
                ? _value.isAuthenticated
                : isAuthenticated // ignore: cast_nullable_to_non_nullable
                      as bool,
            pendingGroupSelection: null == pendingGroupSelection
                ? _value.pendingGroupSelection
                : pendingGroupSelection // ignore: cast_nullable_to_non_nullable
                      as bool,
            pendingOficinaSelection: null == pendingOficinaSelection
                ? _value.pendingOficinaSelection
                : pendingOficinaSelection // ignore: cast_nullable_to_non_nullable
                      as bool,
            pendingPasswordChange: null == pendingPasswordChange
                ? _value.pendingPasswordChange
                : pendingPasswordChange // ignore: cast_nullable_to_non_nullable
                      as bool,
            availableGroups: null == availableGroups
                ? _value.availableGroups
                : availableGroups // ignore: cast_nullable_to_non_nullable
                      as List<GrupoItem>,
            availableOficinas: null == availableOficinas
                ? _value.availableOficinas
                : availableOficinas // ignore: cast_nullable_to_non_nullable
                      as List<OficinaItem>,
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
    int? oficinaId,
    bool isAuthenticated,
    bool pendingGroupSelection,
    bool pendingOficinaSelection,
    bool pendingPasswordChange,
    List<GrupoItem> availableGroups,
    List<OficinaItem> availableOficinas,
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
    Object? oficinaId = freezed,
    Object? isAuthenticated = null,
    Object? pendingGroupSelection = null,
    Object? pendingOficinaSelection = null,
    Object? pendingPasswordChange = null,
    Object? availableGroups = null,
    Object? availableOficinas = null,
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
        oficinaId: freezed == oficinaId
            ? _value.oficinaId
            : oficinaId // ignore: cast_nullable_to_non_nullable
                  as int?,
        isAuthenticated: null == isAuthenticated
            ? _value.isAuthenticated
            : isAuthenticated // ignore: cast_nullable_to_non_nullable
                  as bool,
        pendingGroupSelection: null == pendingGroupSelection
            ? _value.pendingGroupSelection
            : pendingGroupSelection // ignore: cast_nullable_to_non_nullable
                  as bool,
        pendingOficinaSelection: null == pendingOficinaSelection
            ? _value.pendingOficinaSelection
            : pendingOficinaSelection // ignore: cast_nullable_to_non_nullable
                  as bool,
        pendingPasswordChange: null == pendingPasswordChange
            ? _value.pendingPasswordChange
            : pendingPasswordChange // ignore: cast_nullable_to_non_nullable
                  as bool,
        availableGroups: null == availableGroups
            ? _value._availableGroups
            : availableGroups // ignore: cast_nullable_to_non_nullable
                  as List<GrupoItem>,
        availableOficinas: null == availableOficinas
            ? _value._availableOficinas
            : availableOficinas // ignore: cast_nullable_to_non_nullable
                  as List<OficinaItem>,
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
    this.oficinaId,
    this.isAuthenticated = false,
    this.pendingGroupSelection = false,
    this.pendingOficinaSelection = false,
    this.pendingPasswordChange = false,
    final List<GrupoItem> availableGroups = const [],
    final List<OficinaItem> availableOficinas = const [],
  }) : _availableGroups = availableGroups,
       _availableOficinas = availableOficinas;

  @override
  final String? token;
  @override
  final int? userId;
  @override
  final int? grupoOficinaId;
  @override
  final int? oficinaId;
  @override
  @JsonKey()
  final bool isAuthenticated;
  @override
  @JsonKey()
  final bool pendingGroupSelection;
  @override
  @JsonKey()
  final bool pendingOficinaSelection;
  @override
  @JsonKey()
  final bool pendingPasswordChange;
  final List<GrupoItem> _availableGroups;
  @override
  @JsonKey()
  List<GrupoItem> get availableGroups {
    if (_availableGroups is EqualUnmodifiableListView) return _availableGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableGroups);
  }

  final List<OficinaItem> _availableOficinas;
  @override
  @JsonKey()
  List<OficinaItem> get availableOficinas {
    if (_availableOficinas is EqualUnmodifiableListView)
      return _availableOficinas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableOficinas);
  }

  @override
  String toString() {
    return 'AuthState(token: $token, userId: $userId, grupoOficinaId: $grupoOficinaId, oficinaId: $oficinaId, isAuthenticated: $isAuthenticated, pendingGroupSelection: $pendingGroupSelection, pendingOficinaSelection: $pendingOficinaSelection, pendingPasswordChange: $pendingPasswordChange, availableGroups: $availableGroups, availableOficinas: $availableOficinas)';
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
            (identical(other.oficinaId, oficinaId) ||
                other.oficinaId == oficinaId) &&
            (identical(other.isAuthenticated, isAuthenticated) ||
                other.isAuthenticated == isAuthenticated) &&
            (identical(other.pendingGroupSelection, pendingGroupSelection) ||
                other.pendingGroupSelection == pendingGroupSelection) &&
            (identical(
                  other.pendingOficinaSelection,
                  pendingOficinaSelection,
                ) ||
                other.pendingOficinaSelection == pendingOficinaSelection) &&
            (identical(other.pendingPasswordChange, pendingPasswordChange) ||
                other.pendingPasswordChange == pendingPasswordChange) &&
            const DeepCollectionEquality().equals(
              other._availableGroups,
              _availableGroups,
            ) &&
            const DeepCollectionEquality().equals(
              other._availableOficinas,
              _availableOficinas,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    token,
    userId,
    grupoOficinaId,
    oficinaId,
    isAuthenticated,
    pendingGroupSelection,
    pendingOficinaSelection,
    pendingPasswordChange,
    const DeepCollectionEquality().hash(_availableGroups),
    const DeepCollectionEquality().hash(_availableOficinas),
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
    final int? oficinaId,
    final bool isAuthenticated,
    final bool pendingGroupSelection,
    final bool pendingOficinaSelection,
    final bool pendingPasswordChange,
    final List<GrupoItem> availableGroups,
    final List<OficinaItem> availableOficinas,
  }) = _$AuthStateImpl;

  @override
  String? get token;
  @override
  int? get userId;
  @override
  int? get grupoOficinaId;
  @override
  int? get oficinaId;
  @override
  bool get isAuthenticated;
  @override
  bool get pendingGroupSelection;
  @override
  bool get pendingOficinaSelection;
  @override
  bool get pendingPasswordChange;
  @override
  List<GrupoItem> get availableGroups;
  @override
  List<OficinaItem> get availableOficinas;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthStateImplCopyWith<_$AuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
