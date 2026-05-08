import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';
part 'auth_state.g.dart';

@freezed
class GrupoItem with _$GrupoItem {
  const factory GrupoItem({
    required int id,
    required String nome,
  }) = _GrupoItem;

  factory GrupoItem.fromJson(Map<String, dynamic> json) =>
      _$GrupoItemFromJson(json);
}

@freezed
class OficinaItem with _$OficinaItem {
  const factory OficinaItem({
    required int id,
    required String nome,
  }) = _OficinaItem;

  factory OficinaItem.fromJson(Map<String, dynamic> json) =>
      _$OficinaItemFromJson(json);
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    String? token,
    int? userId,
    int? grupoOficinaId,
    int? oficinaId,
    @Default(false) bool isAuthenticated,
    @Default(false) bool pendingGroupSelection,
    @Default(false) bool pendingOficinaSelection,
    @Default([]) List<GrupoItem> availableGroups,
    @Default([]) List<OficinaItem> availableOficinas,
  }) = _AuthState;

  factory AuthState.initial() => const AuthState();
}
