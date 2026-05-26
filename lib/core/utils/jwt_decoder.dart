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

  static String? nome(String token) => _claims(token)['name'] as String?;
  static String? cargo(String token) => _claims(token)['role'] as String?;

  static String? cargoLabel(String token) => _claims(token)['roleLabel'] as String?;

  static int? userId(String token) {
    final v = _claims(token)['sub'];
    return v != null ? int.tryParse(v.toString()) : null;
  }

  static int? grupoOficinaId(String token) {
    final v = _claims(token)['grupoOficinaId'];
    return v != null ? int.tryParse(v.toString()) : null;
  }

  static int? oficinaId(String token) {
    final v = _claims(token)['oficinaId'];
    return v != null ? int.tryParse(v.toString()) : null;
  }

  static bool permissaoGerenciarOficinas(String token) =>
      _claims(token)['gerenciarOficinas'] == 'true';

  static bool isAdmin(String token) =>
      _claims(token)['role'] == '0';

  static int? funcionarioId(String token) {
    final v = _claims(token)['funcionarioId'];
    return v != null ? int.tryParse(v.toString()) : null;
  }
}
