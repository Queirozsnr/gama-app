import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/csv_download.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/receitas_dashboard.dart';
import 'receitas_notifier.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

String _fmtK(double v) {
  if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}k';
  return _fmt(v);
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}';

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

String _monthLabel(int month) => const [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ][month - 1];

String _formaPagLabel(String? fp) {
  if (fp == null) return '—';
  return switch (fp) {
    'Pix'           => 'PIX',
    'Dinheiro'      => 'DINHEIRO',
    'CartaoDebito'  => 'DÉBITO',
    'CartaoCredito' => 'CRÉDITO',
    'Transferencia' => 'TRANSF.',
    _               => fp.toUpperCase(),
  };
}

String _csvNome(String prefixo, DateTime ini, DateTime fim) {
  String d(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  return '${prefixo}_${d(ini)}_${d(fim)}.csv';
}

String _bom() => '﻿';

Future<void> _exportPagamentos(
    List<PagamentoRecente> pagamentos, DateTime ini, DateTime fim) async {
  final buf = StringBuffer()..write(_bom());
  buf.writeln('Data/Hora;OS;Cliente;Forma de Pagamento;Valor');
  for (final p in pagamentos) {
    final d = p.dataHora;
    final data =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final valor = p.valor.toStringAsFixed(2).replaceAll('.', ',');
    buf.writeln('$data;#${p.ordemServicoId};${p.clienteNome};${_formaPagLabel(p.formaPagamento)};$valor');
  }
  await downloadCsv(buf.toString(), _csvNome('pagamentos', ini, fim));
}

Future<void> _exportMecanicos(
    List<ReceitaPorMecanico> mecanicos, DateTime ini, DateTime fim) async {
  final buf = StringBuffer()..write(_bom());
  buf.writeln('Mecânico;Total OS;Ticket Médio;Receita');
  for (final m in mecanicos) {
    final ticket = m.ticketMedio.toStringAsFixed(2).replaceAll('.', ',');
    final receita = m.receita.toStringAsFixed(2).replaceAll('.', ',');
    buf.writeln('${m.nome};${m.totalOs};$ticket;$receita');
  }
  await downloadCsv(buf.toString(), _csvNome('receita_mecanicos', ini, fim));
}

Future<void> _exportLucroOwner(
    List<ReceitaPorMecanico> mecanicos, DateTime ini, DateTime fim) async {
  final buf = StringBuffer()..write(_bom());
  buf.writeln('Mecânico;Tipo;Comissão %;Total OS;Lucro Líquido');
  for (final m in mecanicos) {
    final comissao = m.porcentagem != null ? '${m.porcentagem}%' : '—';
    final liquido = m.liquidoOwner.toStringAsFixed(2).replaceAll('.', ',');
    buf.writeln('${m.nome};${m.tipoRemuneracao};$comissao;${m.totalOs};$liquido');
  }
  await downloadCsv(buf.toString(), _csvNome('lucro_mecanicos', ini, fim));
}

Color _formaPagColor(String? fp) => switch (fp) {
      'Pix'           => AppColors.info,
      'Dinheiro'      => AppColors.ok,
      'CartaoDebito'  => AppColors.accent,
      'CartaoCredito' => AppColors.warn,
      'Transferencia' => AppColors.ink2,
      _               => AppColors.ink3,
    };

// ── period enum ───────────────────────────────────────────────────────────────

enum _Periodo { hoje, semana, mes, mesPassado, trimestre, ano }

extension _PeriodoExt on _Periodo {
  String get label => switch (this) {
        _Periodo.hoje       => 'Hoje',
        _Periodo.semana     => 'Esta semana',
        _Periodo.mes        => 'Este mês',
        _Periodo.mesPassado => 'Mês passado',
        _Periodo.trimestre  => 'Trimestre',
        _Periodo.ano        => 'Ano',
      };

  (DateTime, DateTime) get range {
    final now = DateTime.now();
    return switch (this) {
      _Periodo.hoje => (
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      _Periodo.semana => (
        now.subtract(Duration(days: now.weekday - 1)),
        now,
      ),
      _Periodo.mes => (
        DateTime(now.year, now.month, 1),
        now,
      ),
      _Periodo.mesPassado => () {
          final first = DateTime(now.year, now.month - 1, 1);
          final last = DateTime(now.year, now.month, 0, 23, 59, 59);
          return (first, last);
        }(),
      _Periodo.trimestre => (
        DateTime(now.year, now.month - 2, 1),
        now,
      ),
      _Periodo.ano => (
        DateTime(now.year, 1, 1),
        now,
      ),
    };
  }
}

// ── screen ────────────────────────────────────────────────────────────────────

class ReceitasScreen extends ConsumerStatefulWidget {
  const ReceitasScreen({super.key});

  @override
  ConsumerState<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends ConsumerState<ReceitasScreen>
    with TopBarSlotMixin<ReceitasScreen> {
  _Periodo _periodo = _Periodo.mes;
  late DateTime _dataInicio;
  late DateTime _dataFim;

  @override
  void initState() {
    super.initState();
    _applyPeriodo(_periodo);
  }

  void _applyPeriodo(_Periodo p) {
    final (inicio, fim) = p.range;
    _periodo = p;
    _dataInicio = inicio;
    _dataFim = fim;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot() {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final nome = oficinas.cast<OficinaItem?>().firstWhere(
      (o) => o!.id == auth?.oficinaId,
      orElse: () => null,
    )?.nome;
    setTopBarSlot(TopBarSlot(
      pageTitle: 'Receitas',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      mobileAction: IconButton(
        onPressed: () => GamaSnackBar.error(context, 'Impressão em breve.'),
        icon: const Icon(Icons.print_outlined),
        color: Colors.white,
        tooltip: 'Imprimir',
      ),
      action: OutlinedButton.icon(
        onPressed: () => GamaSnackBar.error(context, 'Impressão em breve.'),
        icon: const Icon(Icons.print_outlined, size: 16),
        label: const Text('Imprimir'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final asyncData =
        ref.watch(receitasDashboardProvider((_dataInicio, _dataFim)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodoBar(
          periodo: _periodo,
          dataInicio: _dataInicio,
          dataFim: _dataFim,
          onChanged: (p) => setState(() => _applyPeriodo(p)),
        ),
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.ink3),
                  const SizedBox(height: 12),
                  Text('Erro ao carregar receitas: $e',
                      style: const TextStyle(color: AppColors.ink2)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(
                        receitasDashboardProvider((_dataInicio, _dataFim))),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            data: (d) => _Body(
              dashboard: d,
              periodo: _periodo,
              dataInicio: _dataInicio,
              dataFim: _dataFim,
              onRefresh: () async => ref.invalidate(
                  receitasDashboardProvider((_dataInicio, _dataFim))),
            ),
          ),
        ),
      ],
    );
  }
}

// ── period bar ────────────────────────────────────────────────────────────────

class _PeriodoBar extends StatelessWidget {
  const _PeriodoBar({
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
    required this.onChanged,
  });

  final _Periodo periodo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final ValueChanged<_Periodo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text(
            'PERÍODO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._Periodo.values.map((p) {
                      final active = p == periodo;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => onChanged(p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: active ? AppColors.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: active
                                      ? AppColors.ink
                                      : Colors.transparent),
                            ),
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.ink2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.ink3),
                          const SizedBox(width: 5),
                          Text(
                            '${_fmtDate(dataInicio)} – ${_fmtDate(dataFim)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.dashboard,
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
    required this.onRefresh,
  });

  final ReceitasDashboard dashboard;
  final _Periodo periodo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _KpiCard(dashboard: dashboard, periodo: periodo, dataInicio: dataInicio, dataFim: dataFim),
        const SizedBox(height: 20),
        _ChartCard(dashboard: dashboard),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final pags = dashboard.pagamentosRecentes;
          final mecs = dashboard.receitaPorMecanico;
          final ini = dataInicio;
          final fim = dataFim;

          final pagCard = _PagamentosRecentesCard(
            pagamentos: pags,
            onExport: () => _exportPagamentos(pags, ini, fim),
          );
          final mecCard = _ReceitaMecanicoCard(
            mecanicos: mecs,
            onExport: () => _exportMecanicos(mecs, ini, fim),
          );
          final lucroCard = _LucroOwnerPorMecanicoCard(
            mecanicos: mecs,
            onExport: () => _exportLucroOwner(mecs, ini, fim),
          );

          // ≥ 1000px — 3 colunas
          if (w >= 1000) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: pagCard),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: mecCard),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: lucroCard),
              ],
            );
          }

          // 600–999px — pagamentos full + 2 colunas abaixo
          if (w >= 600) {
            return Column(
              children: [
                pagCard,
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: mecCard),
                    const SizedBox(width: 12),
                    Expanded(child: lucroCard),
                  ],
                ),
              ],
            );
          }

          // < 600px — tudo empilhado
          return Column(
            children: [
              pagCard,
              const SizedBox(height: 12),
              mecCard,
              const SizedBox(height: 12),
              lucroCard,
            ],
          );
        }),
        const SizedBox(height: 16),
        _DistribuicaoMecanicosCard(
          mecanicos: dashboard.receitaPorMecanico,
          receitaTotal: dashboard.receitaBruta,
        ),
      ],
    );
    if (isDesktop) return list;
    return RefreshIndicator(onRefresh: onRefresh, child: list);
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.dashboard,
    required this.periodo,
    required this.dataInicio,
    required this.dataFim,
  });

  final ReceitasDashboard dashboard;
  final _Periodo periodo;
  final DateTime dataInicio;
  final DateTime dataFim;

  String get _periodoLabel {
    final dias = dataFim.difference(dataInicio).inDays + 1;
    if (periodo == _Periodo.hoje) return 'HOJE';
    if (periodo == _Periodo.mes) {
      return '${_monthLabel(dataInicio.month).toUpperCase()} ${dataInicio.year}';
    }
    return '$dias DIAS';
  }

  @override
  Widget build(BuildContext context) {
    final margem = dashboard.receitaBruta > 0
        ? (dashboard.lucroLiquido / dashboard.receitaBruta * 100)
            .clamp(0, 100)
            .toInt()
        : 0;

    final receitaBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'RECEITA · $_periodoLabel',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _fmt(dashboard.receitaBruta),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (dashboard.receitaBruta / math.max(dashboard.receitaBruta * 2, 1))
                .clamp(0.0, 1.0),
            backgroundColor: AppColors.sidebarLine,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${dashboard.totalOs} OS no período',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.sidebarText,
          ),
        ),
      ],
    );
    final despesasBlock = _KpiBlock(
      label: 'DESPESAS',
      value: _fmtK(dashboard.despesas),
      sub: 'Peças · folha · fixos',
    );
    final lucroBlock = _KpiBlock(
      label: 'LUCRO LÍQUIDO',
      value: _fmtK(dashboard.lucroLiquido),
      sub: 'Margem $margem%',
      valueColor: AppColors.accent,
    );
    final ticketBlock = _KpiBlock(
      label: 'TICKET MÉDIO',
      value: _fmt(dashboard.ticketMedio),
      sub: '${dashboard.totalOs} OS pagas',
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 520) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: receitaBlock),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: despesasBlock),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: lucroBlock),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: ticketBlock),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            receitaBlock,
            const SizedBox(height: 20),
            const Divider(color: AppColors.sidebarLine, height: 1),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: despesasBlock),
                const SizedBox(width: 16),
                Expanded(child: lucroBlock),
                const SizedBox(width: 16),
                Expanded(child: ticketBlock),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _KpiBlock extends StatelessWidget {
  const _KpiBlock({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor = Colors.white,
  });

  final String label;
  final String value;
  final String sub;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.sidebarText,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(fontSize: 11, color: AppColors.sidebarText),
        ),
      ],
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.dashboard});
  final ReceitasDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receita diária',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Clique nas barras para detalhes',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.accent, label: 'Recebido'),
                  const SizedBox(width: 12),
                  _LegendDot(
                      color: AppColors.ink3,
                      label: 'Meta diária',
                      isDash: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: dashboard.receitaDiaria.isEmpty
                ? const Center(
                    child: Text('Sem dados no período',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.ink3)))
                : _BarChart(data: dashboard.receitaDiaria),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(
      {required this.color, required this.label, this.isDash = false});
  final Color color;
  final String label;
  final bool isDash;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isDash
            ? SizedBox(
                width: 16,
                child: Divider(
                    color: color, thickness: 1.5, height: 0),
              )
            : Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
      ],
    );
  }
}

class _BarChart extends StatefulWidget {
  const _BarChart({required this.data});
  final List<ReceitaDiaria> data;

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final maxVal =
        widget.data.map((d) => d.valor).reduce(math.max);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final n = widget.data.length;
      final barW = math.max(8.0, (w / n) * 0.55);
      final gap = (w - barW * n) / math.max(n - 1, 1);
      const labelH = 28.0;
      const topPad = 24.0;
      final chartH = h - labelH - topPad;

      return Stack(
        children: [
          // Gridlines
          CustomPaint(
            size: Size(w, h),
            painter:
                _GridPainter(chartH: chartH, topPad: topPad, labelH: labelH),
          ),
          // Bars + tooltips
          ...List.generate(n, (i) {
            final d = widget.data[i];
            final barH = maxVal > 0
                ? (d.valor / maxVal * chartH).clamp(4.0, chartH)
                : 4.0;
            final x = i * (barW + gap);
            final y = topPad + chartH - barH;
            final isHovered = _hovered == i;

            return Positioned(
              left: x,
              top: 0,
              width: barW,
              height: h,
              child: GestureDetector(
                onTap: () => setState(
                    () => _hovered = _hovered == i ? null : i),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovered = i),
                  onExit: (_) => setState(
                      () => _hovered = _hovered == i ? null : _hovered),
                  child: Stack(
                    children: [
                      // Bar
                      Positioned(
                        left: 0,
                        top: y,
                        width: barW,
                        height: barH,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? AppColors.accent
                                : AppColors.ink,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      // Tooltip on hover
                      if (isHovered)
                        Positioned(
                          top: math.max(0, y - 30),
                          left: -20,
                          right: -20,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _fmtK(d.valor),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Date label
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: labelH,
                          child: Center(
                            child: Text(
                              _fmtDate(d.data),
                              style: TextStyle(
                                fontSize: 9,
                                color: isHovered
                                    ? AppColors.accent
                                    : AppColors.ink3,
                                fontWeight: isHovered
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(
      {required this.chartH, required this.topPad, required this.labelH});
  final double chartH;
  final double topPad;
  final double labelH;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartH - (chartH / 3 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

// ── Export button ─────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Exportar CSV',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.download_outlined, size: 16, color: AppColors.ink3),
        ),
      ),
    );
  }
}

// ── Recent payments card ──────────────────────────────────────────────────────

class _PagamentosRecentesCard extends StatelessWidget {
  const _PagamentosRecentesCard({required this.pagamentos, required this.onExport});
  final List<PagamentoRecente> pagamentos;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 16, color: AppColors.ink3),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagamentos recentes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${pagamentos.length} no período',
                  style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                ),
                const SizedBox(width: 4),
                _ExportButton(onTap: onExport),
              ],
            ),
          ),
          const Divider(height: 1),
          if (pagamentos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Sem pagamentos no período',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.ink3)),
              ),
            )
          else
            ...pagamentos.map((p) => _PagamentoRow(pagamento: p)),
        ],
      ),
    );
  }
}

class _PagamentoRow extends StatelessWidget {
  const _PagamentoRow({required this.pagamento});
  final PagamentoRecente pagamento;

  @override
  Widget build(BuildContext context) {
    final isToday = pagamento.dataHora.day == DateTime.now().day &&
        pagamento.dataHora.month == DateTime.now().month;
    final dateStr = isToday
        ? 'Hoje ${_fmtTime(pagamento.dataHora)}'
        : '${_fmtDate(pagamento.dataHora)} ${_fmtTime(pagamento.dataHora)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dateStr,
              style: const TextStyle(fontSize: 11, color: AppColors.ink3),
            ),
          ),
          Text(
            '#${pagamento.ordemServicoId}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pagamento.clienteNome,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _FormaBadge(forma: pagamento.formaPagamento),
          const SizedBox(width: 12),
          Text(
            _fmt(pagamento.valor),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormaBadge extends StatelessWidget {
  const _FormaBadge({required this.forma});
  final String? forma;

  @override
  Widget build(BuildContext context) {
    final color = _formaPagColor(forma);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formaPagLabel(forma),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Revenue by mechanic card ──────────────────────────────────────────────────

class _ReceitaMecanicoCard extends StatelessWidget {
  const _ReceitaMecanicoCard({required this.mecanicos, required this.onExport});
  final List<ReceitaPorMecanico> mecanicos;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(Icons.engineering_outlined, size: 16, color: AppColors.ink3),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receita por mecânico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Quem está faturando mais',
                        style: TextStyle(fontSize: 11, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ),
                _ExportButton(onTap: onExport),
              ],
            ),
          ),
          const Divider(height: 1),
          if (mecanicos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Sem mecânicos no período',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.ink3)),
              ),
            )
          else
            ...mecanicos.map((m) => _MecanicoRow(mecanico: m)),
        ],
      ),
    );
  }
}

class _MecanicoRow extends StatelessWidget {
  const _MecanicoRow({required this.mecanico});
  final ReceitaPorMecanico mecanico;

  String get _initials {
    final parts = mecanico.nome.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return mecanico.nome
        .substring(0, mecanico.nome.length.clamp(0, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mecanico.nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mecanico.totalOs} OS · ticket ${_fmt(mecanico.ticketMedio)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.ink2),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (mecanico.progressPct / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _fmtK(mecanico.receita),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lucro do dono por mecânico ────────────────────────────────────────────────

class _LucroOwnerPorMecanicoCard extends StatelessWidget {
  const _LucroOwnerPorMecanicoCard({required this.mecanicos, required this.onExport});
  final List<ReceitaPorMecanico> mecanicos;
  final VoidCallback onExport;

  String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return nome.substring(0, nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: AppColors.ink3),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meu lucro por mecânico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Receita líquida após deduzir a % de cada um',
                        style: TextStyle(fontSize: 11, color: AppColors.ink3),
                      ),
                    ],
                  ),
                ),
                _ExportButton(onTap: onExport),
              ],
            ),
          ),
          const Divider(height: 1),
          if (mecanicos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Sem mecânicos no período',
                    style: TextStyle(fontSize: 12, color: AppColors.ink3)),
              ),
            )
          else
            ...mecanicos.map((m) {
              final isFix = m.tipoRemuneracao == 'Fixo';
              final subLabel = isFix
                  ? 'Salário fixo · ${m.totalOs} OS'
                  : '${m.porcentagem ?? 0}% comissão · ${m.totalOs} OS';

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.okSoft,
                      child: Text(
                        _initials(m.nome),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ok,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.nome,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subLabel,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.ink2),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (m.liquidoOwnerProgressPct / 100)
                                  .clamp(0.0, 1.0),
                              backgroundColor: AppColors.line,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppColors.ok),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtK(m.liquidoOwner),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ok,
                          ),
                        ),
                        if (!isFix)
                          Text(
                            'de ${_fmtK(m.receita)}',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.ink3),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Distribuição % por mecânico ───────────────────────────────────────────────

const _mecColors = [
  AppColors.accent,
  AppColors.ok,
  AppColors.info,
  AppColors.warn,
  AppColors.danger,
  AppColors.ink2,
];

class _DistribuicaoMecanicosCard extends StatelessWidget {
  const _DistribuicaoMecanicosCard({
    required this.mecanicos,
    required this.receitaTotal,
  });

  final List<ReceitaPorMecanico> mecanicos;
  final double receitaTotal;

  @override
  Widget build(BuildContext context) {
    if (mecanicos.isEmpty || receitaTotal <= 0) return const SizedBox.shrink();

    final items = mecanicos.asMap().entries.map((e) {
      final pct = e.value.receita / receitaTotal * 100;
      return (
        mecanico: e.value,
        pct: pct,
        color: _mecColors[e.key % _mecColors.length],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 16, color: AppColors.ink3),
              SizedBox(width: 8),
              Text(
                'Participação na receita',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '% do total faturado por mecânico',
                style: TextStyle(fontSize: 11, color: AppColors.ink3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 20,
              child: Row(
                children: items.map((item) => Flexible(
                      flex: (item.pct * 100).round().clamp(1, 10000),
                      child: Container(color: item.color),
                    )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: items.map((item) {
              final pctStr = item.pct.toStringAsFixed(1);
              return SizedBox(
                width: 160,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.mecanico.nome,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pctStr%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _fmtK(item.mecanico.receita),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
