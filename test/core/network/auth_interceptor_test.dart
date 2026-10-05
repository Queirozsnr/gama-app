import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gama_app/core/network/auth_interceptor.dart';
import 'package:gama_app/core/storage/token_storage_interface.dart';

class _MemoryStorage implements TokenStorage {
  @override
  Future<String?> read() async => 'token';
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

/// Responde toda request com o status e o JSON informados.
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  (Dio, List<String>) criarDio(int status, Map<String, dynamic> body) {
    final chamadas = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://teste'))
      ..httpClientAdapter = _FixedAdapter(status, body)
      ..interceptors.add(AuthInterceptor(
        _MemoryStorage(),
        'http://teste',
        onRefreshFailed: () => chamadas.add('refresh'),
        onPlanLimitReached: (msg) => chamadas.add('limite:$msg'),
        onGrupoBloqueado: (tipo, msg) => chamadas.add('$tipo:$msg'),
      ));
    return (dio, chamadas);
  }

  for (final tipo in ['plan_expired', 'account_disabled']) {
    test('402 $tipo avisa o bloqueio e completa a request com erro (não fica pendurada)', () async {
      final (dio, chamadas) = criarDio(402, {'error': 'bloqueado', 'type': tipo});

      await expectLater(
        dio.get<dynamic>('/painel').timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 402)),
      );
      expect(chamadas, ['$tipo:bloqueado']);
    });
  }

  test('402 plan_limit continua só avisando o limite', () async {
    final (dio, chamadas) = criarDio(402, {'error': 'limite', 'type': 'plan_limit'});

    await expectLater(dio.get<dynamic>('/os'), throwsA(isA<DioException>()));
    expect(chamadas, ['limite:limite']);
  });
}
