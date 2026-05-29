const kTokenStorageKey = 'gama_auth_token';
const kRefreshTokenStorageKey = 'gama_refresh_token';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();

  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<void> deleteRefreshToken();
}
