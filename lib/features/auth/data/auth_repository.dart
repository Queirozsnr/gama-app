import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_response.dart';
import '../domain/auth_state.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository(this._dataSource, this._storage);

  final AuthRemoteDataSource _dataSource;
  final TokenStorage _storage;

  Future<LoginResponse> login(String email, String senha) async {
    final response = await _dataSource.login(LoginRequest(email: email, senha: senha));
    await _saveTokens(response);
    return response;
  }

  Future<LoginResponse> selectGroup(int userId, int grupoOficinaId) async {
    final response = await _dataSource.selectGroup(
      SelectGroupRequest(userId: userId, grupoOficinaId: grupoOficinaId),
    );
    await _saveTokens(response);
    return response;
  }

  Future<LoginResponse> selecionarOficina(int oficinaId) async {
    final response = await _dataSource.selecionarOficina(
      SelectOficinaRequest(oficinaId: oficinaId),
    );
    await _saveTokens(response);
    return response;
  }

  Future<void> _saveTokens(LoginResponse response) async {
    if (response.token != null) await _storage.write(response.token!);
    if (response.refreshToken != null) await _storage.writeRefreshToken(response.refreshToken!);
  }

  Future<List<GrupoItem>> fetchGroups() async {
    final raw = await _dataSource.fetchGroups();
    return raw.map((e) => GrupoItem.fromJson(e)).toList();
  }

  Future<List<OficinaItem>> fetchOficinas() async {
    final raw = await _dataSource.fetchOficinas();
    return raw.map((e) => OficinaItem.fromJson(e)).toList();
  }

  Future<void> logout() async {
    await _storage.delete();
    await _storage.deleteRefreshToken();
  }

  Future<String?> getStoredToken() async => _storage.read();

  Future<String?> getStoredRefreshToken() async => _storage.readRefreshToken();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  ),
);
