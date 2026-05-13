import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/veiculos_remote_data_source.dart';
import '../domain/veiculo.dart';

class VeiculosNotifier extends AutoDisposeAsyncNotifier<List<Veiculo>> {
  String? _ultimaBusca;

  @override
  Future<List<Veiculo>> build() => _carregar();

  Future<List<Veiculo>> _carregar({String? busca, int? clienteId}) {
    return ref.read(veiculosRemoteDataSourceProvider).listar(busca: busca, clienteId: clienteId);
  }

  Future<void> buscar(String? termo) async {
    _ultimaBusca = (termo == null || termo.isEmpty) ? null : termo;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _carregar(busca: _ultimaBusca));
  }

  Future<void> criar(Map<String, dynamic> data) async {
    await ref.read(veiculosRemoteDataSourceProvider).criar(data);
    state = await AsyncValue.guard(() => _carregar(busca: _ultimaBusca));
  }

  Future<void> atualizar(int id, Map<String, dynamic> data) async {
    await ref.read(veiculosRemoteDataSourceProvider).atualizar(id, data);
    state = await AsyncValue.guard(() => _carregar(busca: _ultimaBusca));
  }

  Future<void> excluir(int id) async {
    await ref.read(veiculosRemoteDataSourceProvider).excluir(id);
    state = await AsyncValue.guard(() => _carregar(busca: _ultimaBusca));
  }
}

final veiculosNotifierProvider =
    AsyncNotifierProvider.autoDispose<VeiculosNotifier, List<Veiculo>>(VeiculosNotifier.new);
