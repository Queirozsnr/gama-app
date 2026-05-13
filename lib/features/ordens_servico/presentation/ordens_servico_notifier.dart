import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ordens_servico_remote_data_source.dart';
import '../domain/ordem_servico.dart';
import '../domain/ordem_servico_detalhe.dart';

class OrdensServicoNotifier extends AutoDisposeAsyncNotifier<List<OrdemServico>> {
  String? _filtroStatus;

  @override
  Future<List<OrdemServico>> build() => _fetch();

  Future<List<OrdemServico>> _fetch() =>
      ref.read(ordensServicoRemoteDataSourceProvider).listar(status: _filtroStatus);

  Future<void> filtrar(String? status) async {
    _filtroStatus = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> recarregar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> excluir(int id) async {
    await ref.read(ordensServicoRemoteDataSourceProvider).excluir(id);
    state = AsyncData((state.valueOrNull ?? []).where((os) => os.id != id).toList());
  }
}

final ordensServicoNotifierProvider =
    AsyncNotifierProvider.autoDispose<OrdensServicoNotifier, List<OrdemServico>>(
        OrdensServicoNotifier.new);

// Provider para detalhe individual (usado na OsDetalheScreen)
final osDetalheProvider = FutureProvider.autoDispose.family<OrdemServicoDetalhe, int>(
  (ref, id) => ref.read(ordensServicoRemoteDataSourceProvider).obter(id),
);
