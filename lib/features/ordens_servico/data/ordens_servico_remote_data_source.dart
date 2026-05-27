import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/ordem_servico.dart';
import '../domain/ordem_servico_detalhe.dart';

class OrdensServicoRemoteDataSource {
  OrdensServicoRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<OrdemServico>> listar({
    String? status,
    int? clienteId,
    int? veiculoId,
    int? funcionarioId,
    bool excluirEntregue = false,
    String? dataInicio,
    String? dataFim,
    String? ordenar,
  }) async {
    final resp = await _dio.get('/ordens-servico', queryParameters: {
      'status': ?status,
      'clienteId': ?clienteId,
      'veiculoId': ?veiculoId,
      'funcionarioId': ?funcionarioId,
      'dataInicio': ?dataInicio,
      'dataFim': ?dataFim,
      'ordenar': ?ordenar,
      if (excluirEntregue) 'excluirEntregue': true,
    });
    return (resp.data as List)
        .map((e) => OrdemServico.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrdemServicoDetalhe> obter(int id) async {
    final resp = await _dio.get('/ordens-servico/$id');
    return OrdemServicoDetalhe.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<int> criar(Map<String, dynamic> data) async {
    final resp = await _dio.post('/ordens-servico', data: data);
    return (resp.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizar(int id, Map<String, dynamic> data) async {
    await _dio.put('/ordens-servico/$id', data: data);
  }

  Future<void> alterarStatus(int id, String status) async {
    await _dio.patch('/ordens-servico/$id/status', data: {'status': status});
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/ordens-servico/$id');
  }

  Future<void> adicionarMecanico(int osId, int funcionarioId) async {
    await _dio.post('/ordens-servico/$osId/mecanicos', data: {'funcionarioId': funcionarioId});
  }

  Future<void> removerMecanico(int osId, int funcionarioId) async {
    await _dio.delete('/ordens-servico/$osId/mecanicos/$funcionarioId');
  }

  Future<void> ingressar(int osId) async {
    await _dio.post('/ordens-servico/$osId/ingressar');
  }

  Future<int> adicionarItem(int osId, Map<String, dynamic> data) async {
    final resp = await _dio.post('/ordens-servico/$osId/itens', data: data);
    return (resp.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> atualizarItem(int osId, int itemId, Map<String, dynamic> data) async {
    await _dio.put('/ordens-servico/$osId/itens/$itemId', data: data);
  }

  Future<void> removerItem(int osId, int itemId) async {
    await _dio.delete('/ordens-servico/$osId/itens/$itemId');
  }

  Future<int> adicionarDesconto(int osId, Map<String, dynamic> data) async {
    final resp = await _dio.post('/ordens-servico/$osId/descontos', data: data);
    return (resp.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> removerDesconto(int osId, int descontoId) async {
    await _dio.delete('/ordens-servico/$osId/descontos/$descontoId');
  }

  Future<int> adicionarMidia(int osId, Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'arquivo': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final resp = await _dio.post(
      '/ordens-servico/$osId/midias',
      data: formData,
    );
    return (resp.data as Map<String, dynamic>)['id'] as int;
  }

  Future<void> removerMidia(int osId, int midiaId) async {
    await _dio.delete('/ordens-servico/$osId/midias/$midiaId');
  }
}

final ordensServicoRemoteDataSourceProvider = Provider((ref) =>
    OrdensServicoRemoteDataSource(ref.read(dioClientProvider)));
