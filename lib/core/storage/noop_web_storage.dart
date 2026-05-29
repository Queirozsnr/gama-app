import 'token_storage_interface.dart';

class WebTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {}

  @override
  Future<void> deleteRefreshToken() async {}
}
