import 'package:dio/dio.dart';
import '../domain/notificacao.dart';

class NotificacoesRemoteDataSource {
  NotificacoesRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Notificacao>> listar() async {
    final res = await _dio.get<List>('/notificacoes');
    return (res.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Notificacao.fromJson)
        .toList();
  }

  Future<void> marcarLida(int id) =>
      _dio.post<void>('/notificacoes/$id/lida');

  Future<void> marcarTodasLidas() =>
      _dio.post<void>('/notificacoes/lidas');

  Future<void> registrarFcmToken(String token) =>
      _dio.post<void>('/notificacoes/fcm-token', data: {'token': token});

  Future<void> revogarFcmToken(String token) =>
      _dio.delete<void>('/notificacoes/fcm-token', data: {'token': token});
}
