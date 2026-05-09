import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/funcionarios_remote_data_source.dart';
import '../domain/funcionario.dart';

class FuncionariosNotifier extends AutoDisposeAsyncNotifier<List<Funcionario>> {
  @override
  Future<List<Funcionario>> build() => _fetch();

  Future<List<Funcionario>> _fetch({String? busca}) {
    return ref.read(funcionariosRemoteDataSourceProvider).listar(busca: busca);
  }

  Future<void> buscar(String? termo) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(busca: termo?.isEmpty == true ? null : termo));
  }

  Future<void> criar(Map<String, dynamic> data) async {
    await ref.read(funcionariosRemoteDataSourceProvider).criar(data);
    ref.invalidateSelf();
  }

  Future<void> atualizar(int id, Map<String, dynamic> data) async {
    await ref.read(funcionariosRemoteDataSourceProvider).atualizar(id, data);
    ref.invalidateSelf();
  }

  Future<void> excluir(int id) async {
    await ref.read(funcionariosRemoteDataSourceProvider).excluir(id);
    ref.invalidateSelf();
  }

  Future<void> resetarSenha(int id) async {
    await ref.read(funcionariosRemoteDataSourceProvider).resetarSenha(id);
  }
}

final funcionariosNotifierProvider =
    AsyncNotifierProvider.autoDispose<FuncionariosNotifier, List<Funcionario>>(FuncionariosNotifier.new);
