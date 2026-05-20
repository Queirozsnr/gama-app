import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_provider.dart';

const kTokenStorageKey = 'gama_auth_token';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class _SecureTokenStorage implements TokenStorage {
  _SecureTokenStorage(this._ref);
  final Ref _ref;

  @override
  Future<String?> read() =>
      _ref.read(secureStorageProvider).read(key: kTokenStorageKey);

  @override
  Future<void> write(String token) =>
      _ref.read(secureStorageProvider).write(key: kTokenStorageKey, value: token);

  @override
  Future<void> delete() =>
      _ref.read(secureStorageProvider).delete(key: kTokenStorageKey);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => _SecureTokenStorage(ref),
);
