import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage_web.dart' if (dart.library.io) 'token_storage_stub.dart';

const kTokenStorageKey = 'gama_auth_token';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class _NativeTokenStorage implements TokenStorage {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: kTokenStorageKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: kTokenStorageKey, value: token);

  @override
  Future<void> delete() => _storage.delete(key: kTokenStorageKey);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => kIsWeb ? createWebTokenStorage() : _NativeTokenStorage(),
);
