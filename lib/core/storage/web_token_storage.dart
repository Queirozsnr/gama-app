import 'package:web/web.dart';
import 'token_storage_interface.dart';

class WebTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async =>
      window.localStorage.getItem(kTokenStorageKey);

  @override
  Future<void> write(String token) async =>
      window.localStorage.setItem(kTokenStorageKey, token);

  @override
  Future<void> delete() async =>
      window.localStorage.removeItem(kTokenStorageKey);

  @override
  Future<String?> readRefreshToken() async =>
      window.localStorage.getItem(kRefreshTokenStorageKey);

  @override
  Future<void> writeRefreshToken(String token) async =>
      window.localStorage.setItem(kRefreshTokenStorageKey, token);

  @override
  Future<void> deleteRefreshToken() async =>
      window.localStorage.removeItem(kRefreshTokenStorageKey);
}
