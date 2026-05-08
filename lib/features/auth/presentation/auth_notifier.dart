import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref.read(authRepositoryProvider).getStoredToken();
    if (token != null) {
      final groups = await _fetchGroups();
      return AuthState(
        token: token,
        userId: JwtDecoder.userId(token),
        grupoOficinaId: JwtDecoder.grupoOficinaId(token),
        isAuthenticated: true,
        availableGroups: groups,
      );
    }
    return AuthState.initial();
  }

  Future<void> login(String email, String senha) async {
    try {
      final response = await ref.read(authRepositoryProvider).login(email, senha);

      if (response.selecioneGrupo != null && response.selecioneGrupo!.isNotEmpty) {
        state = AsyncData(AuthState(
          userId: response.userId,
          pendingGroupSelection: true,
          availableGroups: response.selecioneGrupo!
              .map((g) => GrupoItem(id: g.id, nome: g.nome))
              .toList(),
        ));
        return;
      }

      final groups = await _fetchGroups();
      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        isAuthenticated: true,
        availableGroups: groups,
      ));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw (data is Map && data['error'] != null)
          ? data['error'] as String
          : 'Erro ao realizar login.';
    } catch (e) {
      throw 'Erro inesperado.';
    }
  }

  Future<void> selectGroup(int grupoOficinaId) async {
    final current = state.value;
    if (current?.userId == null) return;

    try {
      final response = await ref
          .read(authRepositoryProvider)
          .selectGroup(current!.userId!, grupoOficinaId);

      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        isAuthenticated: true,
        availableGroups: current.availableGroups,
      ));
    } on DioException catch (_) {
      throw 'Erro ao selecionar grupo.';
    } catch (_) {
      throw 'Erro inesperado.';
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = AsyncData(AuthState.initial());
  }

  Future<List<GrupoItem>> _fetchGroups() async {
    try {
      return await ref.read(authRepositoryProvider).fetchGroups();
    } catch (_) {
      return [];
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
