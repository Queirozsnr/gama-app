import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class PreviaExclusaoConta {
  const PreviaExclusaoConta({
    required this.permitida,
    this.motivo,
    required this.oficinasExcluidas,
    required this.diasAteApagar,
  });

  final bool permitida;
  final String? motivo;

  /// Oficinas em que o usuário é o único gestor: vão junto com a conta.
  final List<String> oficinasExcluidas;
  final int diasAteApagar;

  factory PreviaExclusaoConta.fromJson(Map<String, dynamic> json) => PreviaExclusaoConta(
        permitida: json['permitida'] as bool,
        motivo: json['motivo'] as String?,
        oficinasExcluidas: (json['oficinasExcluidas'] as List)
            .map((o) => (o as Map<String, dynamic>)['nome'] as String)
            .toList(),
        diasAteApagar: json['diasAteApagar'] as int,
      );
}

class ContaRemoteDataSource {
  ContaRemoteDataSource(this._dio);
  final Dio _dio;

  Future<PreviaExclusaoConta> previaExclusao() async {
    final res = await _dio.get('/conta/exclusao');
    return PreviaExclusaoConta.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> excluir({required String senha, required String confirmacao}) async {
    await _dio.post('/conta/excluir', data: {'senha': senha, 'confirmacao': confirmacao});
  }
}

final contaRemoteDataSourceProvider = Provider<ContaRemoteDataSource>(
  (ref) => ContaRemoteDataSource(ref.watch(dioClientProvider)),
);
