import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../notificacoes/presentation/notificacoes_notifier.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await ref.read(authRepositoryProvider).getStoredToken();
    if (token != null) {
      final groups = await _fetchGroups();
      final oficinas = await _fetchOficinas();
      final currentToken = await ref.read(authRepositoryProvider).getStoredToken();
      if (currentToken == null) return AuthState.initial();

      return AuthState(
        token: currentToken,
        userId: JwtDecoder.userId(currentToken),
        grupoOficinaId: JwtDecoder.grupoOficinaId(currentToken),
        oficinaId: JwtDecoder.oficinaId(currentToken),
        isAuthenticated: true,
        availableGroups: groups,
        availableOficinas: oficinas,
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
          availableGroups: response.selecioneGrupo!,
        ));
        return;
      }

      if (response.selecioneOficina != null && response.selecioneOficina!.isNotEmpty) {
        final groups = await _fetchGroups();
        final oficinas = await _fetchOficinas();
        state = AsyncData(AuthState(
          token: response.token,
          userId: response.userId,
          grupoOficinaId: response.grupoOficinaId,
          pendingOficinaSelection: true,
          availableGroups: groups,
          availableOficinas: oficinas.isNotEmpty ? oficinas : response.selecioneOficina!,
        ));
        return;
      }

      final groups = await _fetchGroups();
      final oficinas = await _fetchOficinas();
      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        oficinaId: response.oficinaId,
        isAuthenticated: true,
        pendingPasswordChange: response.precisaTrocarSenha,
        availableGroups: groups,
        availableOficinas: oficinas,
      ));
      _registrarFcmToken();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) throw data['error'] as String;
      throw 'Erro ao realizar login.';
    } catch (_) {
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

      if (response.selecioneOficina != null && response.selecioneOficina!.isNotEmpty) {
        final oficinas = await _fetchOficinas();
        state = AsyncData(AuthState(
          token: response.token,
          userId: response.userId,
          grupoOficinaId: response.grupoOficinaId,
          pendingOficinaSelection: true,
          availableGroups: current.availableGroups,
          availableOficinas: oficinas.isNotEmpty ? oficinas : response.selecioneOficina!,
        ));
        return;
      }

      final oficinas = await _fetchOficinas();
      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        oficinaId: response.oficinaId,
        isAuthenticated: true,
        availableGroups: current.availableGroups,
        availableOficinas: oficinas,
      ));
    } on DioException catch (_) {
      throw 'Erro ao selecionar grupo.';
    } catch (_) {
      throw 'Erro inesperado.';
    }
  }

  Future<void> selectOficina(int oficinaId) async {
    final current = state.value;

    try {
      final response = await ref.read(authRepositoryProvider).selecionarOficina(oficinaId);

      state = AsyncData(AuthState(
        token: response.token,
        userId: response.userId,
        grupoOficinaId: response.grupoOficinaId,
        oficinaId: response.oficinaId,
        isAuthenticated: true,
        availableGroups: current?.availableGroups ?? [],
        availableOficinas: current?.availableOficinas ?? [],
      ));
    } on DioException catch (_) {
      throw 'Erro ao selecionar oficina.';
    } catch (_) {
      throw 'Erro inesperado.';
    }
  }

  Future<void> confirmarTrocaSenha() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(pendingPasswordChange: false));
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      try {
        final fcmToken = await FcmService.getToken();
        if (fcmToken != null) {
          await ref.read(notificacoesDataSourceProvider).revogarFcmToken(fcmToken);
        }
      } catch (_) {}
      await FcmService.deleteToken();
    }
    await ref.read(authRepositoryProvider).logout();
    state = AsyncData(AuthState.initial());
  }

  Future<void> _registrarFcmToken() async {
    if (kIsWeb) return;
    try {
      final fcmToken = await FcmService.getToken();
      if (fcmToken != null) {
        await ref.read(notificacoesDataSourceProvider).registrarFcmToken(fcmToken);
      }
    } catch (_) {}
  }

  Future<List<GrupoItem>> _fetchGroups() async {
    try {
      return await ref.read(authRepositoryProvider).fetchGroups();
    } catch (_) {
      return [];
    }
  }

  Future<List<OficinaItem>> _fetchOficinas() async {
    try {
      return await ref.read(authRepositoryProvider).fetchOficinas();
    } catch (_) {
      return [];
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
