import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/oficinas_repository.dart';
import '../domain/oficina_model.dart';

class OficinasNotifier extends AutoDisposeAsyncNotifier<List<OficinaModel>> {
  @override
  Future<List<OficinaModel>> build() => ref.read(oficinasRepositoryProvider).listar();

  Future<void> criar({required String nome, required String endereco, required String telefone}) =>
      _run(() => ref.read(oficinasRepositoryProvider).criar(nome: nome, endereco: endereco, telefone: telefone));

  Future<void> atualizar(int id, {required String nome, required String endereco, required String telefone, required bool ativo}) =>
      _run(() => ref.read(oficinasRepositoryProvider).atualizar(id, nome: nome, endereco: endereco, telefone: telefone, ativo: ativo));

  Future<void> excluir(int id) =>
      _run(() => ref.read(oficinasRepositoryProvider).excluir(id));

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      ref.invalidateSelf();
      await future;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw (data is Map && data['error'] != null) ? data['error'] as String : 'Erro na operação.';
    } catch (_) {
      throw 'Erro inesperado.';
    }
  }
}

final oficinasNotifierProvider =
    AsyncNotifierProvider.autoDispose<OficinasNotifier, List<OficinaModel>>(OficinasNotifier.new);
