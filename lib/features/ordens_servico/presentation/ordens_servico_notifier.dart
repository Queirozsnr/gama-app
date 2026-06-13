import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ordens_servico_remote_data_source.dart';
import '../domain/ordem_servico.dart';
import '../domain/ordem_servico_detalhe.dart';
import '../domain/os_resumo.dart';

enum OsPeriodo { hoje, semana, mes, tudo }

// ── OsListState ───────────────────────────────────────────────────────────────

class OsListState {
  const OsListState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<OrdemServico> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  OsListState copyWith({
    List<OrdemServico>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      OsListState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

// ── OrdensServicoNotifier ─────────────────────────────────────────────────────

class OrdensServicoNotifier extends AutoDisposeAsyncNotifier<OsListState> {
  static const _pageSize = 30;

  String? _filtroStatus;
  OsPeriodo _periodo = OsPeriodo.tudo;

  @override
  Future<OsListState> build() => _fetchPage(1);

  Future<OsListState> _fetchPage(int page) async {
    final (inicio, fim) = _datas(_periodo);
    final result = await ref.read(ordensServicoRemoteDataSourceProvider).listar(
          status: _filtroStatus,
          dataInicio: inicio,
          dataFim: fim,
          page: page,
          pageSize: _pageSize,
        );
    return OsListState(
      items: result.items,
      page: page,
      hasMore: result.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final (inicio, fim) = _datas(_periodo);
      final result = await ref.read(ordensServicoRemoteDataSourceProvider).listar(
            status: _filtroStatus,
            dataInicio: inicio,
            dataFim: fim,
            page: current.page + 1,
            pageSize: _pageSize,
          );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...result.items],
        page: current.page + 1,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
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
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<void> setPeriodo(OsPeriodo periodo) async {
    _periodo = periodo;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<void> recarregar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<void> excluir(int id) async {
    await ref.read(ordensServicoRemoteDataSourceProvider).excluir(id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(
        items: current.items.where((os) => os.id != id).toList(),
      ));
    }
  }

  OsPeriodo get periodo => _periodo;
}

final ordensServicoNotifierProvider =
    AsyncNotifierProvider.autoDispose<OrdensServicoNotifier, OsListState>(
        OrdensServicoNotifier.new);

// ── OsResumoNotifier ──────────────────────────────────────────────────────────

class OsResumoNotifier
    extends AutoDisposeFamilyAsyncNotifier<OsResumo, (String?, String?)> {
  @override
  Future<OsResumo> build((String?, String?) arg) {
    final (inicio, fim) = arg;
    return ref
        .read(ordensServicoRemoteDataSourceProvider)
        .resumo(dataInicio: inicio, dataFim: fim);
  }
}

final osResumoProvider = AsyncNotifierProvider.autoDispose
    .family<OsResumoNotifier, OsResumo, (String?, String?)>(
        OsResumoNotifier.new);

// ── osDetalheProvider ─────────────────────────────────────────────────────────

final osDetalheProvider = FutureProvider.autoDispose.family<OrdemServicoDetalhe, int>(
  (ref, id) => ref.read(ordensServicoRemoteDataSourceProvider).obter(id),
);
