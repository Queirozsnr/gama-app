import 'dart:convert';

abstract final class JwtDecoder {
  static Map<String, dynamic> _claims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String? nome(String token) =>
      _claims(token)['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] as String?;

  static String? cargo(String token) =>
      _claims(token)['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] as String?;
}
