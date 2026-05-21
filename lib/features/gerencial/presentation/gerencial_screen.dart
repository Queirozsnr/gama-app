import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/section_card.dart';
import '../domain/gerencial_dashboard.dart';
import 'gerencial_notifier.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v < 0) return '-${_fmt(-v)}';
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

String _fmtK(double v) {
  if (v < 0) return '-${_fmtK(-v)}';
  if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}k';
  return _fmt(v);
}

String _fmtDelta(double v, {bool pp = false}) {
  final sign = v >= 0 ? '+' : '';
  final suffix = pp ? ' pp' : '%';
  return '$sign${v.toStringAsFixed(1)}$suffix';
}

// ── period enum ───────────────────────────────────────────────────────────────

enum _Periodo { hoje, sete, trinta, mes, trimestre }

extension _PeriodoExt on _Periodo {
  String get label => switch (this) {
        _Periodo.hoje      => 'Hoje',
        _Periodo.sete      => '7 dias',
        _Periodo.trinta    => '30 dias',
        _Periodo.mes       => 'Este mês',
        _Periodo.trimestre => 'Trimestre',
      };

  (DateTime, DateTime) get range {
    final now = DateTime.now();
    return switch (this) {
      _Periodo.hoje => (
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      _Periodo.sete => (
        now.subtract(const Duration(days: 6)),
        now,
      ),
      _Periodo.trinta => (
        now.subtract(const Duration(days: 29)),
        now,
      ),
      _Periodo.mes => (
        DateTime(now.year, now.month, 1),
        now,
      ),
      _Periodo.trimestre => (
        DateTime(now.year, now.month - 2, 1),
        now,
      ),
    };
  }
}

// ── screen ────────────────────────────────────────────────────────────────────

class GerencialScreen extends ConsumerStatefulWidget {
  const GerencialScreen({super.key});

  @override
  ConsumerState<GerencialScreen> createState() => _GerencialScreenState();
}

class _GerencialScreenState extends ConsumerState<GerencialScreen>
    with TopBarSlotMixin<GerencialScreen> {
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
    setTopBarSlot(const TopBarSlot(pageTitle: 'Painel'));
  }

  @override
  Widget build(BuildContext context) {
    final asyncData =
        ref.watch(gerencialDashboardProvider((_dataInicio, _dataFim)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodoBar(
          periodo: _periodo,
          onChanged: (p) => setState(() => _applyPeriodo(p)),
        ),
        Expanded(
          child: asyncData.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.ink3),
                  const SizedBox(height: 12),
                  Text('Erro ao carregar dashboard: $e',
                      style: const TextStyle(color: AppColors.ink2)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(
                        gerencialDashboardProvider((_dataInicio, _dataFim))),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            data: (d) => _Body(
              dashboard: d,
              periodo: _periodo,
            ),
          ),
        ),
      ],
    );
  }
}

// ── period bar ────────────────────────────────────────────────────────────────

class _PeriodoBar extends StatelessWidget {
  const _PeriodoBar({required this.periodo, required this.onChanged});

  final _Periodo periodo;
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
          ..._Periodo.values.map((p) {
            final active = p == periodo;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
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
        ],
      ),
    );
  }
}

// ── body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.dashboard, required this.periodo});

  final GerencialDashboard dashboard;
  final _Periodo periodo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KpiRow(dashboard: dashboard, width: w),
            const SizedBox(height: 16),
            _PerformancePorUnidadeCard(dashboard: dashboard),
            const SizedBox(height: 16),
            if (w >= 900)
              _BottomRow3(dashboard: dashboard)
            else if (w >= 560)
              _BottomRow2(dashboard: dashboard)
            else
              _BottomRowStacked(dashboard: dashboard),
          ],
        ),
      );
    });
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.dashboard, required this.width});

  final GerencialDashboard dashboard;
  final double width;

  @override
  Widget build(BuildContext context) {
    final d = dashboard;
    final cards = [
      _KpiCard(
        label: 'RECEITA BRUTA',
        value: _fmtK(d.receitaBruta),
        delta: _fmtDelta(d.receitaBrutaDeltaPct),
        deltaPositive: d.receitaBrutaDeltaPct >= 0,
        sub: 'Ticket médio ${_fmtK(d.ticketMedio)}',
      ),
      _KpiCard(
        label: 'LUCRO LÍQUIDO',
        value: _fmtK(d.lucroLiquido),
        delta: _fmtDelta(d.lucroDeltaPp, pp: true),
        deltaPositive: d.lucroDeltaPp >= 0,
        sub: 'Margem ${d.margemLucro.toStringAsFixed(1)}%',
      ),
      _KpiCard(
        label: 'OS NO PERÍODO',
        value: d.totalOs.toString(),
        delta: _fmtDelta(d.totalOsDelta.toDouble()),
        deltaPositive: d.totalOsDelta >= 0,
        sub: 'vs período anterior',
        deltaIsAbs: true,
      ),
      _KpiCard(
        label: 'EQUIPE ATIVA',
        value: '${d.capacidadeUtilizacao.toStringAsFixed(0)}%',
        sub: '${d.totalMecanicos} funcionários',
        showBar: true,
        barValue: d.capacidadeUtilizacao / 100,
      ),
    ];

    if (width >= 900) {
      return Row(
        children: cards
            .map((c) => Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: c,
                )))
            .toList()
          ..last = Expanded(child: cards.last),
      );
    }

    if (width >= 560) {
      return Column(children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
      ]);
    }

    return Column(
      children: cards
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c,
              ))
          .toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive = true,
    this.deltaIsAbs = false,
    this.sub,
    this.showBar = false,
    this.barValue = 0.0,
  });

  final String label;
  final String value;
  final String? delta;
  final bool deltaPositive;
  final bool deltaIsAbs;
  final String? sub;
  final bool showBar;
  final double barValue;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaPositive ? AppColors.ok : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sidebarText,
                  letterSpacing: 0.8,
                ),
              ),
              if (delta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: deltaPositive
                        ? AppColors.ok.withValues(alpha: 0.15)
                        : AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    delta!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: deltaColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.sidebarLine,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.sidebarText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── performance por unidade ───────────────────────────────────────────────────

class _PerformancePorUnidadeCard extends StatelessWidget {
  const _PerformancePorUnidadeCard({required this.dashboard});

  final GerencialDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final maxReceita = dashboard.performancePorOficina
        .map((o) => o.receita)
        .fold(0.0, math.max);

    return SectionCard(
      title: 'Performance por unidade',
      subtitle: '${dashboard.performancePorOficina.length} unidades',
      child: Column(
        children: [
          _TableHeader(),
          ...dashboard.performancePorOficina.map(
            (of) => _UnidadeRow(
              oficina: of,
              maxReceita: maxReceita > 0 ? maxReceita : 1,
            ),
          ),
          if (dashboard.performancePorOficina.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Sem dados para o período',
                style: TextStyle(color: AppColors.ink2, fontSize: 13),
                textAlign: TextAlign.center,
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
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.ink3,
      letterSpacing: 0.5,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('UNIDADE', style: style)),
          Expanded(flex: 4, child: Text('RECEITA', style: style)),
          Expanded(
              flex: 2,
              child: Text('OS / EQUIPE',
                  style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child:
                  Text('TICKET', style: style, textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child:
                  Text('STATUS', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _UnidadeRow extends StatelessWidget {
  const _UnidadeRow({required this.oficina, required this.maxReceita});

  final PerformanceOficina oficina;
  final double maxReceita;

  @override
  Widget build(BuildContext context) {
    final pct = (oficina.receita / maxReceita).clamp(0.0, 1.0);

    final (statusColor, statusBg, statusText) = switch (oficina.statusLabel) {
      'NO_PRAZO' => (AppColors.ok, AppColors.okSoft, 'NO PRAZO'),
      'ATENCAO'  => (AppColors.warn, AppColors.warnSoft, 'ATENÇÃO'),
      _          => (AppColors.danger, AppColors.dangerSoft, 'ABAIXO'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              oficina.nome,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtK(oficina.receita),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: AppColors.line,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${oficina.totalOs} / ${oficina.totalMecanicos}',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtK(oficina.ticketMedio),
              style:
                  const TextStyle(fontSize: 13, color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── bottom row layouts ────────────────────────────────────────────────────────

class _BottomRow3 extends StatelessWidget {
  const _BottomRow3({required this.dashboard});
  final GerencialDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _RankingMecanicosCard(dashboard: dashboard)),
          const SizedBox(width: 12),
          Expanded(child: _ReceitaTipoCard(dashboard: dashboard)),
          const SizedBox(width: 12),
          Expanded(child: _AlertasCard(dashboard: dashboard)),
        ],
      ),
    );
  }
}

class _BottomRow2 extends StatelessWidget {
  const _BottomRow2({required this.dashboard});
  final GerencialDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RankingMecanicosCard(dashboard: dashboard)),
            const SizedBox(width: 12),
            Expanded(child: _ReceitaTipoCard(dashboard: dashboard)),
          ],
        ),
        const SizedBox(height: 12),
        _AlertasCard(dashboard: dashboard),
      ],
    );
  }
}

class _BottomRowStacked extends StatelessWidget {
  const _BottomRowStacked({required this.dashboard});
  final GerencialDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RankingMecanicosCard(dashboard: dashboard),
        const SizedBox(height: 12),
        _ReceitaTipoCard(dashboard: dashboard),
        const SizedBox(height: 12),
        _AlertasCard(dashboard: dashboard),
      ],
    );
  }
}

// ── ranking mecânicos ─────────────────────────────────────────────────────────

class _RankingMecanicosCard extends StatelessWidget {
  const _RankingMecanicosCard({required this.dashboard});
  final GerencialDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final top = dashboard.rankingMecanicos;
    final maxReceita = top.isNotEmpty ? top.first.receita : 1.0;

    return SectionCard(
      title: 'Ranking mecânicos',
      subtitle: 'Top ${top.length} do período',
      child: top.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Sem dados',
                    style: TextStyle(color: AppColors.ink2, fontSize: 13)),
              ),
            )
          : Column(
              children: top.map((m) {
                final pct =
                    (m.receita / maxReceita).clamp(0.0, 1.0);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${m.posicao}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: m.posicao == 1
                                ? AppColors.accent
                                : AppColors.ink3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.nome,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _fmtK(m.receita),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 4,
                                      backgroundColor: AppColors.line,
                                      valueColor:
                                          const AlwaysStoppedAnimation<
                                              Color>(AppColors.accent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${m.totalOs} OS',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.ink2,
                                  ),
                                ),
                              ],
                            ),
                            if (dashboard.performancePorOficina.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  m.oficinaNome,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.ink3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── receita por tipo ──────────────────────────────────────────────────────────

class _ReceitaTipoCard extends StatelessWidget {
  const _ReceitaTipoCard({required this.dashboard});
  final GerencialDashboard dashboard;

  static const _colors = [AppColors.accent, AppColors.info];

  @override
  Widget build(BuildContext context) {
    final tipos = dashboard.receitaPorTipo;

    return SectionCard(
      title: 'Receita por tipo',
      subtitle: 'Serviços vs peças',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (tipos.isNotEmpty) ...[
            _StackedBar(tipos: tipos, colors: _colors),
            const SizedBox(height: 16),
          ],
          ...List.generate(tipos.length, (i) {
            final t = tipos[i];
            final color = _colors[i % _colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.tipo,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                  Text(
                    _fmtK(t.valor),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${t.percentual.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ink2),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (tipos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Sem dados',
                    style: TextStyle(
                        color: AppColors.ink2, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.tipos, required this.colors});

  final List<ReceitaTipo> tipos;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final total =
        tipos.fold(0.0, (sum, t) => sum + t.valor);
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 14,
        child: Row(
          children: List.generate(tipos.length, (i) {
            final pct = tipos[i].valor / total;
            return Expanded(
              flex: (pct * 1000).round(),
              child: Container(
                color: colors[i % colors.length],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── alertas ───────────────────────────────────────────────────────────────────

class _AlertasCard extends StatelessWidget {
  const _AlertasCard({required this.dashboard});
  final GerencialDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final alertas = dashboard.alertas;

    return SectionCard(
      title: 'Atenção',
      subtitle: alertas.isEmpty ? 'Tudo certo!' : '${alertas.length} item(s)',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          if (alertas.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.okSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.ok, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sem alertas no período.',
                      style: TextStyle(
                          color: AppColors.ok, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            ...alertas.map((a) => _AlertaRow(alerta: a)),
        ],
      ),
    );
  }
}

// ── alerta row ────────────────────────────────────────────────────────────────

class _AlertaRow extends StatelessWidget {
  const _AlertaRow({required this.alerta});
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final isWarn = alerta.nivel == 'warning';
    final color = isWarn ? AppColors.warn : AppColors.danger;
    final bgColor = isWarn ? AppColors.warnSoft : AppColors.dangerSoft;
    final icon = isWarn ? Icons.warning_amber_outlined : Icons.error_outline;

    return GestureDetector(
      onTap: alerta.detalhes.isEmpty ? null : () => _showDialog(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alerta.descricao,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (alerta.detalhes.isNotEmpty) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    final isWarn = alerta.nivel == 'warning';
    final color = isWarn ? AppColors.warn : AppColors.danger;
    final icon = isWarn ? Icons.warning_amber_outlined : Icons.error_outline;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // cabeçalho escuro estilo Garage
                Container(
                  color: AppColors.sidebarBg,
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alerta.descricao,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close,
                            color: AppColors.sidebarText, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // lista de itens
                Container(
                  color: AppColors.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...alerta.detalhes.map((d) => _DetalheRow(
                            detalhe: d,
                            color: color,
                            onTap: d.rota == null
                                ? null
                                : () {
                                    Navigator.of(ctx).pop();
                                    context.go('${d.rota!}?from=/home');
                                  },
                          )),
                      // rodapé
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: AppColors.line)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Fechar',
                                style:
                                    TextStyle(color: AppColors.ink2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetalheRow extends StatelessWidget {
  const _DetalheRow({
    required this.detalhe,
    required this.color,
    this.onTap,
  });

  final AlertaDetalhe detalhe;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detalhe.descricao,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward,
                  size: 14, color: AppColors.ink3),
            ],
          ],
        ),
      ),
    );
  }
}
