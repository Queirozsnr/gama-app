import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../domain/auth_response.dart';
import '../domain/auth_state.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository(this._dataSource, this._storage);

  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;

  Future<LoginResponse> login(String email, String senha) async {
    final response = await _dataSource.login(LoginRequest(email: email, senha: senha));
    if (response.token != null) {
      await _storage.write(key: kTokenStorageKey, value: response.token);
    }
    return response;
  }

  Future<LoginResponse> selectGroup(int userId, int grupoOficinaId) async {
    final response = await _dataSource.selectGroup(
      SelectGroupRequest(userId: userId, grupoOficinaId: grupoOficinaId),
    );
    if (response.token != null) {
      await _storage.write(key: kTokenStorageKey, value: response.token);
    }
    return response;
  }

  Future<LoginResponse> selecionarOficina(int oficinaId) async {
    final response = await _dataSource.selecionarOficina(
      SelectOficinaRequest(oficinaId: oficinaId),
    );
    await _storage.write(key: kTokenStorageKey, value: response.token);
    return response;
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
    await _storage.delete(key: kTokenStorageKey);
  }

  Future<String?> getStoredToken() async {
    return _storage.read(key: kTokenStorageKey);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageProvider),
  ),
);
