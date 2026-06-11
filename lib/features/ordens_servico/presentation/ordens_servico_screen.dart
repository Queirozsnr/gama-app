import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/state/top_bar_scope.dart';
import '../../../../shared/widgets/chips/status_chip.dart';
import '../../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
import '../../../../shared/widgets/gama_fab.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../oficinas/domain/oficina_model.dart';
import '../../oficinas/presentation/oficinas_notifier.dart';
import '../domain/ordem_servico.dart';
import 'ordens_servico_notifier.dart';
import 'widgets/os_card.dart';

typedef _PeriodoOpt = ({String label, OsPeriodo value});
const _periodos = <_PeriodoOpt>[
  (label: 'Hoje',        value: OsPeriodo.hoje),
  (label: 'Esta semana', value: OsPeriodo.semana),
  (label: 'Este mês',    value: OsPeriodo.mes),
  (label: 'Tudo',        value: OsPeriodo.tudo),
];

// Sentinel: busca tudo no backend mas oculta 'Entregue' no cliente
const _kSemEntregue = '__sem_entregue__';

typedef _StatusOpt = ({String label, String? value});
const _statusOpts = <_StatusOpt>[
  (label: 'Ativos',  value: _kSemEntregue),
  (label: 'Todas',         value: null),
  (label: 'Aberta',        value: 'Aberta'),
  (label: 'Em Andamento',  value: 'EmAndamento'),
  (label: 'Aguarda Peça',  value: 'AguardandoPecas'),
  (label: 'Pronto',        value: 'Concluida'),
  (label: 'Entregue',      value: 'Entregue'),
];

class OrdensServicoScreen extends ConsumerStatefulWidget {
  const OrdensServicoScreen({super.key});

  @override
  ConsumerState<OrdensServicoScreen> createState() => _OrdensServicoScreenState();
}

class _OrdensServicoScreenState extends ConsumerState<OrdensServicoScreen>
    with TopBarSlotMixin<OrdensServicoScreen>, WidgetsBindingObserver {
  OsPeriodo _periodo = OsPeriodo.tudo;
  String? _filtroStatus = _kSemEntregue;
  String? _filtroMecanico;
  String? _filtroCliente;
  String _ordenarCampo = 'prazo';
  bool _ordenarAsc = true;
  final _buscaCtrl = TextEditingController();
  String _busca = '';
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(ordensServicoNotifierProvider.notifier).recarregar();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot() {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final oficinas =
        ref.read(oficinasNotifierProvider).valueOrNull ?? <OficinaModel>[];
    final nome = oficinas
        .where((o) => o.id == authState?.oficinaId)
        .firstOrNull
        ?.nome;
    setTopBarSlot(TopBarSlot(
      pageTitle: 'Ordens de Serviço',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      mobileAction: IconButton(
        onPressed: _toggleSearch,
        icon: Icon(
          _searchOpen ? Icons.close : Icons.search,
          color: _searchOpen ? AppColors.accent : Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      action: FilledButton.icon(
        onPressed: () => context.go('/ordens-servico/nova'),
        icon: const Icon(Icons.add, size: 17),
        label: const Text('Nova OS'),
      ),
    ));
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _buscaCtrl.clear();
      setState(() => _busca = '');
    }
    _syncSlot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _buscaCtrl.dispose());
    super.dispose();
  }

  void _setPeriodo(OsPeriodo p) {
    setState(() => _periodo = p);
    ref.read(ordensServicoNotifierProvider.notifier).setPeriodo(p);
  }

  void _setStatus(String? v) {
    final prevBackend = _filtroStatus == _kSemEntregue ? null : _filtroStatus;
    final newBackend  = v            == _kSemEntregue ? null : v;
    setState(() => _filtroStatus = v);
    // Só re-busca se o parâmetro enviado ao backend realmente mudou
    if (prevBackend != newBackend) {
      ref.read(ordensServicoNotifierProvider.notifier).filtrar(newBackend);
    }
  }

  void _setMecanico(String? v) => setState(() => _filtroMecanico = v);
  void _setCliente(String? v) => setState(() => _filtroCliente = v);

  void _setOrdenar(String campo, bool asc) =>
      setState(() {
        _ordenarCampo = campo;
        _ordenarAsc = asc;
      });

  List<OrdemServico> _aplicarFiltros(List<OrdemServico> lista) {
    var r = lista;
    if (_filtroStatus == _kSemEntregue) {
      r = r.where((os) => os.status != 'Entregue').toList();
    }
    if (_busca.isNotEmpty) {
      r = r.where((os) =>
        os.clienteNome.toLowerCase().contains(_busca) ||
        os.veiculoDescricao.toLowerCase().contains(_busca) ||
        (os.veiculoPlaca?.toLowerCase().contains(_busca) ?? false),
      ).toList();
    }
    if (_filtroMecanico != null) {
      r = r.where((os) => os.mecanicoNomes.contains(_filtroMecanico)).toList();
    }
    if (_filtroCliente != null) {
      r = r.where((os) => os.clienteNome == _filtroCliente).toList();
    }
    r.sort((a, b) {
      final cmp = switch (_ordenarCampo) {
        'id'    => a.id.compareTo(b.id),
        'prazo' => () {
            if (a.previsaoEntrega == null && b.previsaoEntrega == null) return 0;
            if (a.previsaoEntrega == null) return 1;
            if (b.previsaoEntrega == null) return -1;
            return a.previsaoEntrega!.compareTo(b.previsaoEntrega!);
          }(),
        _       => 0,
      };
      return _ordenarAsc ? cmp : -cmp;
    });
    return r;
  }

  Future<void> _excluir(OrdemServico os) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Excluir OS #${os.id}',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(ordensServicoNotifierProvider.notifier).excluir(os.id);
      if (mounted) GamaSnackBar.success(context, 'OS removida.');
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao excluir OS.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final osAsync = ref.watch(ordensServicoNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final lista = osAsync.valueOrNull ?? const [];

    // Keep slot subtitle fresh when providers load
    ref.listen(authNotifierProvider, (_, _) { if (mounted) _syncSlot(); });
    ref.listen(oficinasNotifierProvider, (_, _) { if (mounted) _syncSlot(); });

    final mecanicos = lista
        .expand((os) => os.mecanicoNomes)
        .toSet()
        .toList()..sort();
    final clientes = lista
        .map((os) => os.clienteNome)
        .toSet()
        .toList()..sort();

    final filtersBar = _FiltrosBar(
      filtroStatus: _filtroStatus,
      filtroMecanico: _filtroMecanico,
      filtroCliente: _filtroCliente,
      ordenarCampo: _ordenarCampo,
      ordenarAsc: _ordenarAsc,
      mecanicos: mecanicos,
      clientes: clientes,
      onStatusChanged: _setStatus,
      onMecanicoChanged: _setMecanico,
      onClienteChanged: _setCliente,
      onOrdenarChanged: _setOrdenar,
    );

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PeriodBar(periodo: _periodo, onChanged: _setPeriodo),
          filtersBar,
          Expanded(
            child: osAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => _ErrorState(
                onRetry: () =>
                    ref.read(ordensServicoNotifierProvider.notifier).recarregar(),
              ),
              data: (loaded) {
                final rows = _aplicarFiltros(loaded);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _KpiCards(lista: loaded, periodo: _periodo),
                      _OsTable(
                        lista: rows,
                        onTap: (os) => context.go('/ordens-servico/${os.id}'),
                        onDelete: _excluir,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Mobile layout
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_searchOpen)
                _MobileSearchRow(
                  controller: _buscaCtrl,
                  onChanged: (v) => setState(() => _busca = v.toLowerCase()),
                ),
              _MobileDarkStats(lista: lista, periodo: _periodo),
              _PeriodBar(periodo: _periodo, onChanged: _setPeriodo),
              filtersBar,
              Expanded(
                child: osAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, st) => _ErrorState(
                    onRetry: () => ref
                        .read(ordensServicoNotifierProvider.notifier)
                        .recarregar(),
                  ),
                  data: (loaded) {
                    final rows = _aplicarFiltros(loaded);
                    return _OsMobileList(
                      lista: rows,
                      onTap: (os) => context.go('/ordens-servico/${os.id}'),
                      onDelete: _excluir,
                      onRefresh: () => ref
                          .read(ordensServicoNotifierProvider.notifier)
                          .recarregar(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: GamaFab(label: 'Nova OS', onTap: () => context.go('/ordens-servico/nova')),
        ),
      ],
    );
  }
}

// ── Period bar ─────────────────────────────────────────────────────────────────

const _meses = [
  '', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _dateRangeLabel(OsPeriodo p) {
  final now = DateTime.now();
  return switch (p) {
    OsPeriodo.hoje   => '${now.day} ${_meses[now.month]} ${now.year}',
    OsPeriodo.semana => () {
        final ini = now.subtract(Duration(days: now.weekday - 1));
        final fim = now.add(Duration(days: 7 - now.weekday));
        return '${ini.day}–${fim.day} ${_meses[fim.month]} ${fim.year}';
      }(),
    OsPeriodo.mes    => '${_meses[now.month]} ${now.year}',
    OsPeriodo.tudo   => 'Todos os períodos',
  };
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({required this.periodo, required this.onChanged});
  final OsPeriodo periodo;
  final ValueChanged<OsPeriodo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              'PERÍODO',
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.ink3,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 12),
            ..._periodos.map((opt) {
              final isActive = opt.value == periodo;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onChanged(opt.value),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive ? AppColors.ink : AppColors.line,
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.ink2,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.ink3),
                  const SizedBox(width: 6),
                  Text(
                    _dateRangeLabel(periodo),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared filter dropdown pill ────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.nullLabel,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final String nullLabel;
  final List<({String label, String? value})> options;
  final ValueChanged<String?> onChanged;

  String get _displayLabel =>
      options.where((o) => o.value == value).firstOrNull?.label ?? nullLabel;

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == '\x00' ? null : v),
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.line),
      ),
      color: AppColors.surface,
      elevation: 8,
      itemBuilder: (_) => options.map((opt) {
        final isSel = opt.value == value;
        return PopupMenuItem<String>(
          value: opt.value ?? '\x00',
          child: Text(
            opt.label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 13,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? AppColors.accent : AppColors.ink,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentSoft : Colors.transparent,
          border: Border.all(
              color: isActive ? AppColors.accent : AppColors.line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $_displayLabel',
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.accent : AppColors.ink2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14,
                color: isActive ? AppColors.accent : AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

// ── Filtros bar ────────────────────────────────────────────────────────────────

class _FiltrosBar extends StatelessWidget {
  const _FiltrosBar({
    required this.filtroStatus,
    required this.filtroMecanico,
    required this.filtroCliente,
    required this.ordenarCampo,
    required this.ordenarAsc,
    required this.mecanicos,
    required this.clientes,
    required this.onStatusChanged,
    required this.onMecanicoChanged,
    required this.onClienteChanged,
    required this.onOrdenarChanged,
  });
  final String? filtroStatus;
  final String? filtroMecanico;
  final String? filtroCliente;
  final String ordenarCampo;
  final bool ordenarAsc;
  final List<String> mecanicos;
  final List<String> clientes;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onMecanicoChanged;
  final ValueChanged<String?> onClienteChanged;
  final void Function(String campo, bool asc) onOrdenarChanged;

  String get _ordenarLabel {
    final opt = _ordenarOpts
        .where((o) => o.campo == ordenarCampo && o.asc == ordenarAsc)
        .firstOrNull;
    return opt?.label ?? 'Prazo ↑';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Text('FILTROS',
                      style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.ink3, letterSpacing: 0.8)),
                  const SizedBox(width: 10),
                  _FilterDropdown(
                    label: 'Mecânico', value: filtroMecanico,
                    nullLabel: 'Todos',
                    options: [
                      (label: 'Todos', value: null),
                      ...mecanicos.map((m) => (label: m, value: m)),
                    ],
                    onChanged: onMecanicoChanged,
                  ),
                  const SizedBox(width: 6),
                  _FilterDropdown(
                    label: 'Status', value: filtroStatus,
                    nullLabel: 'Qualquer',
                    options: _statusOpts
                        .map((o) => (label: o.label, value: o.value))
                        .toList(),
                    onChanged: onStatusChanged,
                  ),
                  const SizedBox(width: 6),
                  _FilterDropdown(
                    label: 'Cliente', value: filtroCliente,
                    nullLabel: 'Qualquer',
                    options: [
                      (label: 'Qualquer', value: null),
                      ...clientes.map((c) => (label: c, value: c)),
                    ],
                    onChanged: onClienteChanged,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: PopupMenuButton<int>(
              onSelected: (i) {
                final opt = _ordenarOpts[i];
                onOrdenarChanged(opt.campo, opt.asc);
              },
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.line),
              ),
              color: AppColors.surface,
              elevation: 8,
              itemBuilder: (_) => _ordenarOpts
                  .asMap()
                  .entries
                  .map((e) => PopupMenuItem<int>(
                        value: e.key,
                        child: Text(e.value.label,
                            style: TextStyle(fontFamily: 'Inter', 
                                fontSize: 13,
                                fontWeight: (e.value.campo == ordenarCampo &&
                                        e.value.asc == ordenarAsc)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: (e.value.campo == ordenarCampo &&
                                        e.value.asc == ordenarAsc)
                                    ? AppColors.accent
                                    : AppColors.ink)),
                      ))
                  .toList(),
              child: Builder(builder: (ctx) {
                final isDesktop = MediaQuery.of(ctx).size.width >= 800;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isDesktop)
                    Text('ORDENAR: ',
                        style: TextStyle(fontFamily: 'Inter',
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.ink3, letterSpacing: 0.8)),
                  Text(_ordenarLabel,
                      style: TextStyle(fontFamily: 'Inter',
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.ink2)),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop: period + filtros + ordenar numa linha ─────────────────────────────

const _ordenarOpts = [
  (label: 'Prazo ↑',   campo: 'prazo', asc: true),
  (label: 'Prazo ↓',   campo: 'prazo', asc: false),
  (label: 'Número ↑',  campo: 'id',    asc: true),
  (label: 'Número ↓',  campo: 'id',    asc: false),
];

// ── KPI cards ─────────────────────────────────────────────────────────────────

class _KpiCards extends StatelessWidget {
  const _KpiCards({required this.lista, required this.periodo});
  final List<OrdemServico> lista;
  final OsPeriodo periodo;

  @override
  Widget build(BuildContext context) {
    final totalOs = lista.length;
    final abertas = lista.where((os) => os.status == 'Aberta').length;
    final prontas = lista.where((os) => os.status == 'Concluida').length;
    final aguarda = lista.where((os) => os.status == 'AguardandoPecas').length;
    final totalValor = lista.fold(0.0, (sum, os) => sum + os.total);
    final periodLabel = switch (periodo) {
      OsPeriodo.hoje   => 'hoje',
      OsPeriodo.semana => 'da semana',
      OsPeriodo.mes    => 'do mês',
      OsPeriodo.tudo   => 'total',
    };

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final useRow = width >= 550;

    final cards = [
      _KpiCardData(
        label: 'OS NO PERÍODO',
        value: '$totalOs',
        subtitle: '$abertas abertas · $prontas prontas',
      ),
      _KpiCardData(
        label: 'VALOR PREVISTO',
        value: _fmtBrl(totalValor),
        subtitle: 'soma $periodLabel',
      ),
      _KpiCardData(
        label: 'CARGA DA EQUIPE',
        value: '—',
        subtitle: 'não calculado',
      ),
      _KpiCardData(
        label: 'AGUARDA PEÇAS',
        value: '$aguarda',
        subtitle: aguarda == 1 ? 'OS bloqueada' : 'OS bloqueadas',
      ),
    ];

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(isDesktop ? 0 : 16, 12, isDesktop ? 0 : 16, 12),
      child: useRow
          ? Row(
              children: cards
                  .map((c) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: cards.indexOf(c) < cards.length - 1 ? 10 : 0,
                          ),
                          child: _KpiCard(data: c),
                        ),
                      ))
                  .toList(),
            )
          : GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cards.map((c) => _KpiCard(data: c)).toList(),
            ),
    );
  }

  String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.label,
    required this.value,
    required this.subtitle,
  });
  final String label;
  final String value;
  final String subtitle;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Desktop table ──────────────────────────────────────────────────────────────

class _OsTable extends StatelessWidget {
  const _OsTable({
    required this.lista,
    required this.onTap,
    required this.onDelete,
  });
  final List<OrdemServico> lista;
  final ValueChanged<OrdemServico> onTap;
  final Future<void> Function(OrdemServico) onDelete;

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) return const _EmptyState();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeader(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: lista.length,
              itemBuilder: (_, i) => _TableRow(
                os: lista[i],
                isLast: i == lista.length - 1,
                isEven: i.isEven,
                onTap: () => onTap(lista[i]),
                onDelete: lista[i].status == 'Aberta'
                    ? () => onDelete(lista[i])
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      color: AppColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          SizedBox(width: 72, child: _ColLabel('OS')),
          SizedBox(width: 148, child: _ColLabel('STATUS')),
          Expanded(flex: 2, child: _ColLabel('SERVIÇO · VEÍCULO')),
          SizedBox(width: 12),
          Expanded(child: _ColLabel('CLIENTE')),
          SizedBox(width: 12),
          Expanded(child: _ColLabel('MECÂNICO')),
          SizedBox(width: 12),
          SizedBox(width: 90, child: _ColLabel('VALOR')),
          SizedBox(width: 12),
          SizedBox(width: 90, child: _ColLabel('PRAZO')),
          SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  const _ColLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.ink3,
          letterSpacing: 0.6,
        ),
      );
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.os,
    required this.isLast,
    required this.isEven,
    required this.onTap,
    this.onDelete,
  });
  final OrdemServico os;
  final bool isLast;
  final bool isEven;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final os = widget.os;
    final status = OsStatus.fromString(os.status);
    final atrasada = os.previsaoEntrega != null &&
        DateTime.now().isAfter(os.previsaoEntrega!) &&
        os.status != 'Concluida' &&
        os.status != 'Entregue';

    final baseColor = widget.isEven ? AppColors.surface : const Color(0xFFF5F5F5);
    final rowColor = _hovered ? AppColors.accentSoft : baseColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 68,
          width: double.infinity,
          decoration: BoxDecoration(
            color: rowColor,
            border: widget.isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.line)),
          ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // OS number + date
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${os.id}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    _fmtShort(os.dataEntrada),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ink3),
                  ),
                ],
              ),
            ),
            // Status chip
            SizedBox(
              width: 148,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusChip(status: status),
              ),
            ),
            // Serviço · Veículo
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (os.primeiroServico != null)
                    Text(
                      os.primeiroServico!,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    children: [
                      if (os.veiculoPlaca != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            os.veiculoPlaca!,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 10,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          os.veiculoDescricao,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 11,
                            color: AppColors.ink2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Cliente
            Expanded(
              child: Text(
                os.clienteNome,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Mecânico com avatar
            Expanded(
              child: os.mecanicoNomes.isEmpty
                  ? Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3))
                  : Row(
                      children: [
                        _Avatar(nome: os.mecanicoNomes.first),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            os.mecanicoNomes.length == 1
                                ? os.mecanicoNomes.first
                                : '${os.mecanicoNomes.first} +${os.mecanicoNomes.length - 1}',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            // Valor
            SizedBox(
              width: 90,
              child: Text(
                _fmtBrl(os.total),
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Prazo
            SizedBox(
              width: 90,
              child: os.previsaoEntrega == null
                  ? Text('—', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ink3))
                  : Text(
                      _fmtDate(os.previsaoEntrega!),
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: atrasada ? FontWeight.w600 : FontWeight.w400,
                        color: atrasada ? AppColors.danger : AppColors.ink2,
                      ),
                    ),
            ),
            // Ações
            SizedBox(
              width: 36,
              child: widget.onDelete != null
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.ink3),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Excluir',
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
  }

  String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  String _fmtShort(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    final initials = nome.trim().split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.ink2,
        ),
      ),
    );
  }
}

// ── Mobile list ────────────────────────────────────────────────────────────────

class _OsMobileList extends StatelessWidget {
  const _OsMobileList({
    required this.lista,
    required this.onTap,
    required this.onDelete,
    required this.onRefresh,
  });
  final List<OrdemServico> lista;
  final ValueChanged<OrdemServico> onTap;
  final Future<void> Function(OrdemServico) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) return const _EmptyState();

    // Group by date label
    final groups = <String, List<OrdemServico>>{};
    for (final os in lista) {
      groups.putIfAbsent(_groupLabel(os.dataEntrada), () => []).add(os);
    }

    // Flat list: header item + card items
    final items = <({String? header, OrdemServico? os, int? count})>[];
    for (final e in groups.entries) {
      items.add((header: e.key, os: null, count: e.value.length));
      for (final os in e.value) {
        items.add((header: null, os: os, count: null));
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16, 8, 16,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          if (item.header != null) {
            return _DateGroupHeader(label: item.header!, count: item.count!);
          }
          final os = item.os!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OsCard(
              os: os,
              onTap: () => onTap(os),
              onLongPress: os.status == 'Aberta' ? () => onDelete(os) : null,
            ),
          );
        },
      ),
    );
  }

  static String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    if (diff == 0) return 'HOJE · $dd/$mm';
    if (diff == -1) return 'ONTEM · $dd/$mm';
    if (diff == 1) return 'AMANHÃ · $dd/$mm';
    return '$dd/$mm/${dt.year}';
  }
}

// ── Mobile dark stats ──────────────────────────────────────────────────────────

class _MobileDarkStats extends StatelessWidget {
  const _MobileDarkStats({required this.lista, required this.periodo});
  final List<OrdemServico> lista;
  final OsPeriodo periodo;

  @override
  Widget build(BuildContext context) {
    final totalOs = lista.length;
    final abertas = lista.where((os) => os.status == 'Aberta').length;
    final prontas = lista.where((os) => os.status == 'Concluida').length;
    final totalValor = lista.fold(0.0, (sum, os) => sum + os.total);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          _StatBox(value: '$totalOs', label: 'PERÍODO'),
          _StatBox(value: '$abertas', label: 'ABERTAS'),
          _StatBox(value: '$prontas', label: 'PRONTAS'),
          _StatBox(value: _fmtShort(totalValor), label: 'PREVISTO'),
        ],
      ),
    );
  }

  static String _fmtShort(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return 'R\$ ${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return 'R\$ ${v.toStringAsFixed(0)}';
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile inline search ───────────────────────────────────────────────────────

class _MobileSearchRow extends StatelessWidget {
  const _MobileSearchRow({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.sidebarLine,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppColors.sidebarText),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cliente, veículo ou placa…',
                  hintStyle: TextStyle(fontFamily: 'Inter', 
                      fontSize: 13, color: AppColors.sidebarText),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date group header ──────────────────────────────────────────────────────────

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error states ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 56, color: AppColors.ink3),
            const SizedBox(height: 12),
            Text(
              'Nenhuma OS encontrada',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink2),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar ordens de serviço',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink2),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
