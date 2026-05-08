import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../domain/auth_response.dart';
import 'auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository(this._dataSource, this._storage);

  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _storage;

  Future<LoginResponse> login(String email, String senha) async {
    final response = await _dataSource.login(
      LoginRequest(email: email, senha: senha),
    );
    if (response.token != null) {
      await _storage.write(key: kTokenStorageKey, value: response.token);
    }
    return response;
  }

  Future<SelectGroupResponse> selectGroup(
    int userId,
    int grupoOficinaId,
  ) async {
    final response = await _dataSource.selectGroup(
      SelectGroupRequest(userId: userId, grupoOficinaId: grupoOficinaId),
    );
    await _storage.write(key: kTokenStorageKey, value: response.token);
    return response;
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
