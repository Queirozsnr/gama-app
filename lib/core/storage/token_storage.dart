import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_provider.dart';
import 'token_storage_interface.dart';
import 'web_token_storage.dart' if (dart.library.io) 'noop_web_storage.dart';

export 'token_storage_interface.dart';

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

  @override
  Future<String?> readRefreshToken() =>
      _ref.read(secureStorageProvider).read(key: kRefreshTokenStorageKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _ref.read(secureStorageProvider).write(key: kRefreshTokenStorageKey, value: token);

  @override
  Future<void> deleteRefreshToken() =>
      _ref.read(secureStorageProvider).delete(key: kRefreshTokenStorageKey);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => kIsWeb ? WebTokenStorage() : _SecureTokenStorage(ref),
);
