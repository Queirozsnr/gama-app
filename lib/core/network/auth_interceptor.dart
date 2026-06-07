import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storage,
    this._baseUrl, {
    required this.onRefreshFailed,
    this.onPlanLimitReached,
    this.onPlanExpired,
  });

  final TokenStorage _storage;
  final String _baseUrl;
  final void Function() onRefreshFailed;

  /// Chamado quando o backend retorna 402 com type "plan_limit" (feature bloqueada).
  final void Function(String mensagem)? onPlanLimitReached;

  /// Chamado quando o backend retorna 402 com type "plan_expired" (assinatura vencida).
  final void Function(String mensagem)? onPlanExpired;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.read();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // storage falhou — prossegue sem token
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 402) {
      final data = err.response?.data;
      final mensagem = (data is Map && data['error'] != null)
          ? data['error'] as String
          : 'Limite do plano atingido. Faça upgrade para continuar.';
      final tipo = (data is Map) ? data['type'] as String? : null;
      if (tipo == 'plan_expired' || tipo == 'account_disabled') {
        onPlanExpired?.call(mensagem);
        // Não completa o handler — request fica em loading enquanto o redirect ocorre
        return;
      } else {
        onPlanLimitReached?.call(mensagem);
        handler.next(err);
      }
      return;
    }

    if (err.response?.statusCode != 401 || _isRefreshing) {
      handler.next(err);
      return;
    }

    // Evita loop infinito na própria chamada de refresh
    if (err.requestOptions.path.contains('/auth/refresh')) {
      await _clearTokens();
      onRefreshFailed();
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) {
        await _clearTokens();
        onRefreshFailed();
        handler.next(err);
        return;
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ));

      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newToken = refreshResponse.data['token'] as String;
      final newRefreshToken = refreshResponse.data['refreshToken'] as String;
      await _storage.write(newToken);
      await _storage.writeRefreshToken(newRefreshToken);

      // Retenta a request original com o novo token
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      final retryResponse = await refreshDio.fetch(opts);
      handler.resolve(retryResponse);
    } catch (_) {
      await _clearTokens();
      onRefreshFailed();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearTokens() async {
    try {
      await _storage.delete();
      await _storage.deleteRefreshToken();
    } catch (_) {}
  }
}
