import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/state/top_bar_scope.dart';
import '../../../../shared/widgets/chips/status_chip.dart';
import '../../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../../shared/widgets/gama_snack_bar.dart';
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

typedef _StatusOpt = ({String label, String? value});
const _statusOpts = <_StatusOpt>[
  (label: 'Todas',        value: null),
  (label: 'ABERTA',       value: 'Aberta'),
  (label: 'EM ANDAMENTO', value: 'EmAndamento'),
  (label: 'AGUARDA PEÇA', value: 'AguardandoPecas'),
  (label: 'PRONTO',       value: 'Concluida'),
  (label: 'ENTREGUE',     value: 'Entregue'),
];

class OrdensServicoScreen extends ConsumerStatefulWidget {
  const OrdensServicoScreen({super.key});

  @override
  ConsumerState<OrdensServicoScreen> createState() => _OrdensServicoScreenState();
}

class _OrdensServicoScreenState extends ConsumerState<OrdensServicoScreen>
    with TopBarSlotMixin<OrdensServicoScreen> {
  OsPeriodo _periodo = OsPeriodo.semana;
  String? _filtroStatus;
  String? _filtroMecanico;
  String? _filtroCliente;
  String _ordenarCampo = 'prazo';
  bool _ordenarAsc = true;
  final _buscaCtrl = TextEditingController();
  String _busca = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setTopBarSlot(TopBarSlot(
      searchController: _buscaCtrl,
      searchHint: 'Buscar por cliente, veículo ou placa…',
      onSearchChanged: (v) => setState(() => _busca = v.toLowerCase()),
      action: FilledButton.icon(
        onPressed: () => context.go('/ordens-servico/nova'),
        icon: const Icon(Icons.add, size: 17),
        label: const Text('Nova OS'),
      ),
      mobileAction: IconButton(
        onPressed: () => context.go('/ordens-servico/nova'),
        icon: const Icon(Icons.add),
        color: AppColors.accent,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buscaCtrl.dispose());
  }

  void _setPeriodo(OsPeriodo p) {
    setState(() => _periodo = p);
    ref.read(ordensServicoNotifierProvider.notifier).setPeriodo(p);
  }

  void _setStatus(String? v) {
    setState(() => _filtroStatus = v);
    ref.read(ordensServicoNotifierProvider.notifier).filtrar(v);
  }

  void _setMecanico(String? v) => setState(() => _filtroMecanico = v);
  void _setCliente(String? v) => setState(() => _filtroCliente = v);

  void _setOrdenar(String campo, bool asc) =>
      setState(() { _ordenarCampo = campo; _ordenarAsc = asc; });

  List<OrdemServico> _aplicarFiltros(List<OrdemServico> lista) {
    var r = lista;

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
        'id'   => a.id.compareTo(b.id),
        'prazo' => () {
            if (a.previsaoEntrega == null && b.previsaoEntrega == null) return 0;
            if (a.previsaoEntrega == null) return 1;
            if (b.previsaoEntrega == null) return -1;
            return a.previsaoEntrega!.compareTo(b.previsaoEntrega!);
          }(),
        _      => 0,
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

    // Unique options extracted from loaded list for local filters
    final mecanicos = lista
        .expand((os) => os.mecanicoNomes)
        .toSet()
        .toList()..sort();
    final clientes = lista
        .map((os) => os.clienteNome)
        .toSet()
        .toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodBar(periodo: _periodo, onChanged: _setPeriodo),
        _FiltrosBar(
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
        ),
        if (!isDesktop) _KpiCards(lista: lista, periodo: _periodo),
        Expanded(
          child: osAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => _ErrorState(
              onRetry: () =>
                  ref.read(ordensServicoNotifierProvider.notifier).recarregar(),
            ),
            data: (loaded) {
              final rows = _aplicarFiltros(loaded);
              if (isDesktop) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _KpiCards(lista: loaded, periodo: _periodo),
                      _OsTable(
                        lista: rows,
                        onTap: (os) =>
                            context.go('/ordens-servico/${os.id}'),
                        onDelete: _excluir,
                      ),
                    ],
                  ),
                );
              }
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
              style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
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
            style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('ORDENAR: ',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppColors.ink3, letterSpacing: 0.8)),
                Text(_ordenarLabel,
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.ink2)),
              ]),
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
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink2),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.hardEdge,
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
        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
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
                      style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Mecânico com avatar
            Expanded(
              child: os.mecanicoNomes.isEmpty
                  ? Text('—', style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3))
                  : Row(
                      children: [
                        _Avatar(nome: os.mecanicoNomes.first),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            os.mecanicoNomes.length == 1
                                ? os.mecanicoNomes.first
                                : '${os.mecanicoNomes.first} +${os.mecanicoNomes.length - 1}',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
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
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Prazo
            SizedBox(
              width: 90,
              child: os.previsaoEntrega == null
                  ? Text('—', style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3))
                  : Text(
                      _fmtDate(os.previsaoEntrega!),
                      style: GoogleFonts.inter(
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
        style: GoogleFonts.inter(
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: lista.length,
        separatorBuilder: (_, i) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final os = lista[i];
          return OsCard(
            os: os,
            onTap: () => onTap(os),
            onLongPress: os.status == 'Aberta' ? () => onDelete(os) : null,
          );
        },
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
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink2),
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
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink2),
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
