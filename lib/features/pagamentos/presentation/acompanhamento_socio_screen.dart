import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/pagamento.dart';
import 'pagamentos_notifier.dart';

enum _Periodo { semana, mes, ano }

extension _PeriodoExt on _Periodo {
  String get label => switch (this) {
        _Periodo.semana => 'Esta semana',
        _Periodo.mes => 'Este mês',
        _Periodo.ano => 'Este ano',
      };

  (DateTime, DateTime) get range {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    return switch (this) {
      _Periodo.semana => (hoje.subtract(const Duration(days: 6)), hoje),
      _Periodo.mes => (DateTime(now.year, now.month, 1), hoje),
      _Periodo.ano => (DateTime(now.year, 1, 1), hoje),
    };
  }
}

class AcompanhamentoSocioScreen extends ConsumerStatefulWidget {
  const AcompanhamentoSocioScreen({
    super.key,
    required this.funcionarioId,
    required this.funcionarioNome,
  });
  final int funcionarioId;
  final String funcionarioNome;

  @override
  ConsumerState<AcompanhamentoSocioScreen> createState() =>
      _AcompanhamentoSocioScreenState();
}

class _AcompanhamentoSocioScreenState
    extends ConsumerState<AcompanhamentoSocioScreen> {
  _Periodo _periodo = _Periodo.mes;

  @override
  Widget build(BuildContext context) {
    final (dataInicio, dataFim) = _periodo.range;
    final asyncData = ref.watch(dashboardSocioProvider((
      widget.funcionarioId,
      dataInicio,
      dataFim,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Receitas', style: TextStyle(fontSize: 17)),
                Text(
                  widget.funcionarioNome,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: _Periodo.values.map((p) {
                    final selected = p == _periodo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _periodo = p),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
        body: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                const Text('Erro ao carregar dados',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(dashboardSocioProvider((
                    widget.funcionarioId,
                    dataInicio,
                    dataFim,
                  ))),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          data: (dashboard) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardSocioProvider((
              widget.funcionarioId,
              dataInicio,
              dataFim,
            ))),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ResumoCard(dashboard: dashboard, periodo: _periodo),
                ),
                if (dashboard.itens.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'ORDENS DE SERVIÇO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: dashboard.itens.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _OsCard(item: dashboard.itens[i]),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Resumo card ─────────────────────────────────────────────────────────────

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({required this.dashboard, required this.periodo});
  final DashboardSocio dashboard;
  final _Periodo periodo;

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryMid, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                periodo.label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${dashboard.quantidadeOS} OS',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Valor Líquido',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(dashboard.valorLiquido),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SubMetric(
                  label: 'Receita Bruta',
                  value: _fmt(dashboard.receitaBruta),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SubMetric(
                  label: 'Deduções',
                  value: '− ${_fmt(dashboard.totalDeducoes)}',
                  dimmed: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubMetric extends StatelessWidget {
  const _SubMetric(
      {required this.label, required this.value, this.dimmed = false});
  final String label;
  final String value;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(dimmed ? 20 : 31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: dimmed ? Colors.white60 : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OS card ─────────────────────────────────────────────────────────────────

class _OsCard extends StatelessWidget {
  const _OsCard({required this.item});
  final DashboardSocioOsItem item;

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  Color get _statusColor => switch (item.status) {
        'Entregue' => AppColors.success,
        'Aberta' => AppColors.primaryLight,
        _ => AppColors.textSecondary,
      };

  Color get _statusBg => switch (item.status) {
        'Entregue' => AppColors.successLight,
        'Aberta' => const Color(0xFFE3F2FD),
        _ => AppColors.border,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clienteNome,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.veiculoInfo,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _date(item.dataEntrada),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _ValorCol(label: 'Receita', value: _fmt(item.totalOS)),
                _divider(),
                _ValorCol(
                  label: 'Deduções',
                  value: '− ${_fmt(item.totalDeducoes)}',
                  color: AppColors.textSecondary,
                ),
                _divider(),
                _ValorCol(
                  label: 'Líquido',
                  value: _fmt(item.valorLiquido),
                  color: AppColors.success,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);
}

class _ValorCol extends StatelessWidget {
  const _ValorCol({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.border),
        SizedBox(height: 16),
        Text(
          'Nenhuma OS neste período',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
