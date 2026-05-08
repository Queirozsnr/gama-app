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
class AuthState with _$AuthState {
  const factory AuthState({
    String? token,
    int? userId,
    int? grupoOficinaId,
    @Default(false) bool isAuthenticated,
    @Default(false) bool pendingGroupSelection,
    @Default([]) List<GrupoItem> availableGroups,
  }) = _AuthState;

  factory AuthState.initial() => const AuthState();
}
