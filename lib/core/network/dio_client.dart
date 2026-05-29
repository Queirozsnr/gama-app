import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import 'api_constants.dart';
import 'auth_interceptor.dart';
import '../storage/token_storage.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: kConnectTimeout,
      receiveTimeout: kReceiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(
    ref.read(tokenStorageProvider),
    kBaseUrl,
    onRefreshFailed: () => ref.invalidate(authNotifierProvider),
  ));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});
