const kTokenStorageKey = 'gama_auth_token';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}
