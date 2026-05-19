// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'token_storage.dart';

class _WebTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => html.window.localStorage[kTokenStorageKey];

  @override
  Future<void> write(String token) async =>
      html.window.localStorage[kTokenStorageKey] = token;

  @override
  Future<void> delete() async =>
      html.window.localStorage.remove(kTokenStorageKey);
}

TokenStorage createWebTokenStorage() => _WebTokenStorage();
