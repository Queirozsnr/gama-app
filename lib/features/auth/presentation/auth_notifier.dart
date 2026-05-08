import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref.read(authRepositoryProvider).getStoredToken();
    if (token != null) {
      return AuthState(token: token, isAuthenticated: true);
    }
    return AuthState.initial();
  }

  // Lança String com a mensagem de erro — a tela gerencia isLoading/erro localmente
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

      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        isAuthenticated: true,
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
    final userId = state.value?.userId;
    if (userId == null) return;

    try {
      final response = await ref
          .read(authRepositoryProvider)
          .selectGroup(userId, grupoOficinaId);

      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        isAuthenticated: true,
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
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
