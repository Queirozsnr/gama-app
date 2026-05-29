import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ordens_servico_remote_data_source.dart';
import '../domain/ordem_servico.dart';
import '../domain/ordem_servico_detalhe.dart';

enum OsPeriodo { hoje, semana, mes, tudo }

class OrdensServicoNotifier extends AutoDisposeAsyncNotifier<List<OrdemServico>> {
  String? _filtroStatus;
  OsPeriodo _periodo = OsPeriodo.tudo;

  @override
  Future<List<OrdemServico>> build() => _fetch();

  Future<List<OrdemServico>> _fetch() {
    final (inicio, fim) = _datas(_periodo);
    return ref.read(ordensServicoRemoteDataSourceProvider).listar(
      status: _filtroStatus,
      dataInicio: inicio,
      dataFim: fim,
    );
  }

  (String?, String?) _datas(OsPeriodo periodo) {
    final now = DateTime.now();
    return switch (periodo) {
      OsPeriodo.hoje   => (_iso(now), _iso(now)),
      OsPeriodo.semana => (_iso(now.subtract(Duration(days: now.weekday - 1))), _iso(now)),
      OsPeriodo.mes    => (_iso(DateTime(now.year, now.month, 1)), _iso(now)),
      OsPeriodo.tudo   => (null, null),
    };
  }

  String _iso(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> filtrar(String? status) async {
    _filtroStatus = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setPeriodo(OsPeriodo periodo) async {
    _periodo = periodo;
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

final osDetalheProvider = FutureProvider.autoDispose.family<OrdemServicoDetalhe, int>(
  (ref, id) => ref.read(ordensServicoRemoteDataSourceProvider).obter(id),
);
