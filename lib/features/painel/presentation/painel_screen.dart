import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/utils/data_refresh.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../domain/painel_operacional.dart';
import 'painel_notifier.dart';

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

String _saudacao() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

String _fmtDataHoje() {
  const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  const meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  final now = DateTime.now();
  return '${dias[now.weekday - 1]}, ${now.day} ${meses[now.month - 1]}'
      .toUpperCase();
}

String _fmtPrevisao(DateTime? dt) {
  if (dt == null) return '—';
  final hoje = DateTime.now();
  final amanha = hoje.add(const Duration(days: 1));
  if (dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day) {
    return 'Hoje';
  }
  if (dt.year == amanha.year &&
      dt.month == amanha.month &&
      dt.day == amanha.day) {
    return 'Amanhã';
  }
  const ds = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return '${ds[dt.weekday - 1]} ${dt.day}';
}

Color _statusColor(String s) => switch (s) {
      'EM ANDAMENTO'   => AppColors.warn,
      'AGUARDA PEÇA'   => AppColors.info,
      'PRONTO'         => AppColors.ok,
      'AGUARDA APROV.' => AppColors.ink3,
      _                => AppColors.ink3,
    };

Color _statusBg(String s) => switch (s) {
      'EM ANDAMENTO'   => AppColors.warnSoft,
      'AGUARDA PEÇA'   => AppColors.infoSoft,
      'PRONTO'         => AppColors.okSoft,
      'AGUARDA APROV.' => AppColors.surface2,
      _                => AppColors.surface2,
    };

// ── period enum ───────────────────────────────────────────────────────────────

enum _Periodo { hoje, semana, mes, mesPassado, trimestre }

extension _PeriodoExt on _Periodo {
  String get label => switch (this) {
        _Periodo.hoje       => 'Hoje',
        _Periodo.semana     => 'Esta semana',
        _Periodo.mes        => 'Este mês',
        _Periodo.mesPassado => 'Mês passado',
        _Periodo.trimestre  => 'Trimestre',
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
      _Periodo.mesPassado => (
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1)),
      ),
      _Periodo.trimestre => (
        DateTime(now.year, now.month - 2, 1),
        now,
      ),
    };
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
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _Periodo.values.map((p) {
            final active = p == periodo;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.accent : AppColors.line,
                    ),
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
          }).toList(),
        ),
      ),
    );
  }
}

// ── screen ────────────────────────────────────────────────────────────────────

class PainelScreen extends ConsumerStatefulWidget {
  const PainelScreen({super.key});

  @override
  ConsumerState<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends ConsumerState<PainelScreen>
    with TopBarSlotMixin<PainelScreen> {
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
      pageTitle: 'Painel',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      mobileAction: const NotificationBell(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final asyncData =
        ref.watch(painelOperacionalProvider((_dataInicio, _dataFim)));

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
                  Text('Erro ao carregar painel: $e',
                      style: const TextStyle(color: AppColors.ink2)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(
                        painelOperacionalProvider((_dataInicio, _dataFim))),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            data: (d) => _Body(
              painel: d,
              periodo: _periodo,
              onRefresh: () async => ref.invalidate(
                  painelOperacionalProvider((_dataInicio, _dataFim))),
            ),
          ),
        ),
      ],
    );
  }
}

// ── body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({required this.painel, required this.periodo, required this.onRefresh});
  final PainelOperacional painel;
  final _Periodo periodo;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final nome = auth?.token != null
        ? (JwtDecoder.nome(auth!.token!)?.split(' ').first ?? '')
        : '';

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 800;
      final scrollView = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeBanner(nome: nome, painel: painel),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _KpiRow(painel: painel, wide: wide, periodo: periodo),
                  const SizedBox(height: 16),
                  if (wide)
                    _BodyWide(painel: painel)
                  else
                    _BodyNarrow(painel: painel),
                ],
              ),
            ),
          ],
        ),
      );
      if (wide) return scrollView;
      return RefreshIndicator(onRefresh: onRefresh, child: scrollView);
    });
  }
}

// ── welcome banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends ConsumerWidget {
  const _WelcomeBanner({required this.nome, required this.painel});
  final String nome;
  final PainelOperacional painel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final oficinaAtual = oficinas.isEmpty
        ? null
        : oficinas.cast<OficinaItem?>().firstWhere(
            (o) => o!.id == auth?.oficinaId,
            orElse: () => oficinas.first);

    final prontas =
        painel.osEmAndamento.where((o) => o.status == 'PRONTO').length;
    final aguardando = painel.emAprovacao;

    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fmtDataHoje(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_saudacao()}${nome.isNotEmpty ? ', $nome.' : '.'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                if (oficinas.length > 1)
                  GestureDetector(
                    onTap: () => _abrirTrocarOficina(context, ref, oficinas, auth?.oficinaId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          oficinaAtual?.nome ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.sidebarText,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more,
                            size: 16, color: AppColors.sidebarText),
                      ],
                    ),
                  )
                else
                  Text(
                    [
                      if (prontas > 0)
                        '$prontas OS ${prontas == 1 ? 'pronta' : 'prontas'} pra entrega',
                      if (aguardando > 0) '$aguardando aguardando aprovação',
                    ].join(' · ').let((s) => s.isEmpty ? 'Sem pendências' : s),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.sidebarText),
                  ),
                if (oficinas.length > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (prontas > 0)
                        '$prontas OS ${prontas == 1 ? 'pronta' : 'prontas'} pra entrega',
                      if (aguardando > 0) '$aguardando aguardando aprovação',
                    ].join(' · ').let((s) => s.isEmpty ? 'Sem pendências' : s),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.ink3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.ordensServicoNova),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Abrir nova OS',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _abrirTrocarOficina(
    BuildContext context,
    WidgetRef ref,
    List<OficinaItem> oficinas,
    int? currentId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TrocarOficinaSheet(
        oficinas: oficinas,
        currentId: currentId,
        onSelect: (id) async {
          await ref.read(authNotifierProvider.notifier).selectOficina(id);
          invalidateAllData(ref);
        },
      ),
    );
  }
}

// ── trocar oficina sheet ──────────────────────────────────────────────────────

class _TrocarOficinaSheet extends StatefulWidget {
  const _TrocarOficinaSheet({
    required this.oficinas,
    required this.currentId,
    required this.onSelect,
  });

  final List<OficinaItem> oficinas;
  final int? currentId;
  final Future<void> Function(int id) onSelect;

  @override
  State<_TrocarOficinaSheet> createState() => _TrocarOficinaSheetState();
}

class _TrocarOficinaSheetState extends State<_TrocarOficinaSheet> {
  int? _loadingId;

  Future<void> _selecionar(int id) async {
    if (id == widget.currentId) {
      Navigator.pop(context);
      return;
    }
    setState(() => _loadingId = id);
    try {
      await widget.onSelect(id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  static String _initials(String nome) {
    final parts = nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return nome.substring(0, nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Trocar unidade',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final o in widget.oficinas) ...[
            InkWell(
              onTap: _loadingId != null ? null : () => _selecionar(o.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    GamaAvatar(initials: _initials(o.nome), size: 38),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        o.nome,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (_loadingId == o.id)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (o.id == widget.currentId)
                      const Icon(Icons.check_circle,
                          color: AppColors.accent, size: 20)
                    else
                      const Icon(Icons.chevron_right,
                          color: AppColors.ink3, size: 20),
                  ],
                ),
              ),
            ),
            if (o != widget.oficinas.last)
              const Divider(height: 1, indent: 72),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

extension _LetExt<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.painel, required this.wide, required this.periodo});
  final PainelOperacional painel;
  final bool wide;
  final _Periodo periodo;

  @override
  Widget build(BuildContext context) {
    final d = painel;
    final cards = [
      _KpiCard(
        label: 'OS ABERTAS',
        value: d.osAbertas.toString(),
        delta: '${d.osAbertasDelta >= 0 ? '+' : ''}${d.osAbertasDelta}',
        deltaPositive: d.osAbertasDelta >= 0,
        sub: 'vs ontem',
      ),
      _KpiCard(
        label: 'FATURAMENTO',
        value: _fmtK(d.faturamentoMes),
        delta:
            '${d.faturamentoMesDeltaPct >= 0 ? '+' : ''}${d.faturamentoMesDeltaPct.toStringAsFixed(1)}%',
        deltaPositive: d.faturamentoMesDeltaPct >= 0,
        sub: periodo.label.toLowerCase(),
      ),
      _KpiCard(
        label: 'EM APROVAÇÃO',
        value: d.emAprovacao.toString(),
        delta: '${d.emAprovacaoDelta >= 0 ? '+' : ''}${d.emAprovacaoDelta}',
        deltaPositive: d.emAprovacaoDelta >= 0,
        sub: 'aguardando',
      ),
      _KpiCard(
        label: 'TICKET MÉDIO',
        value: _fmtK(d.ticketMedio),
        delta:
            '${d.ticketMedioDelta >= 0 ? '+' : ''}${_fmtK(d.ticketMedioDelta.abs())}',
        deltaPositive: d.ticketMedioDelta >= 0,
        sub: periodo.label.toLowerCase(),
      ),
    ];

    if (wide) {
      return Row(
        children: List.generate(cards.length, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
            child: cards[i],
          ),
        )),
      );
    }

    return Column(
      children: [
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
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.sub,
  });

  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaPositive ? AppColors.ok : AppColors.danger;
    final deltaBg = deltaPositive ? AppColors.okSoft : AppColors.dangerSoft;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                    letterSpacing: 0.5,
                  )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(delta,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: deltaColor,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
        ],
      ),
    );
  }
}

// ── body wide ─────────────────────────────────────────────────────────────────

class _BodyWide extends StatelessWidget {
  const _BodyWide({required this.painel});
  final PainelOperacional painel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _OsEmAndamentoCard(painel: painel),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _EquipeCard(painel: painel),
              const SizedBox(height: 16),
              _EstoqueCriticoCard(painel: painel),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyNarrow extends StatelessWidget {
  const _BodyNarrow({required this.painel});
  final PainelOperacional painel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OsEmAndamentoCard(painel: painel),
        const SizedBox(height: 16),
        _EquipeCard(painel: painel),
        const SizedBox(height: 16),
        _EstoqueCriticoCard(painel: painel),
      ],
    );
  }
}

// ── ordens em andamento ───────────────────────────────────────────────────────

class _OsEmAndamentoCard extends StatelessWidget {
  const _OsEmAndamentoCard({required this.painel});
  final PainelOperacional painel;

  @override
  Widget build(BuildContext context) {
    final os = painel.osEmAndamento;
    final total = painel.osAbertas;

    return SectionCard(
      title: 'Ordens em andamento',
      subtitle: '$total ${total == 1 ? 'aberta' : 'abertas'}',
      action: TextButton(
        onPressed: () => context.go(AppRoutes.ordensServico),
        child: const Text('Ver todas →',
            style: TextStyle(color: AppColors.accent, fontSize: 13)),
      ),
      child: os.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Nenhuma OS em andamento',
                    style: TextStyle(color: AppColors.ink2, fontSize: 13)),
              ),
            )
          : Column(
              children: os
                  .map((o) => _OsRow(os: o))
                  .toList(),
            ),
    );
  }
}

class _OsRow extends StatelessWidget {
  const _OsRow({required this.os});
  final OsResumo os;

  Widget _statusBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _statusBg(os.status),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _statusColor(os.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              os.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _statusColor(os.status),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );

  Widget _clientePlacaRow() => Row(
        children: [
          Text(os.clienteNome,
              style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
          if (os.placa != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.sidebarBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                os.placa!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 520;
      return InkWell(
        onTap: () => context.go('/ordens-servico/${os.id}?from=/home'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: compact ? _buildCompact() : _buildFull(),
        ),
      );
    });
  }

  // Mobile: número | serviço+cliente | status+valor empilhados à direita
  Widget _buildCompact() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '#${os.id}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink3,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  os.servico,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _clientePlacaRow(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusBadge(),
              const SizedBox(height: 4),
              Text(
                _fmt(os.valor),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      );

  // Desktop: layout completo com prazo
  Widget _buildFull() => Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '#${os.id}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink3,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  os.servico,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _clientePlacaRow(),
                    if (os.veiculoDescricao != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        os.veiculoDescricao!,
                        style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _statusBadge(),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              _fmt(os.valor),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              _fmtPrevisao(os.previsaoEntrega),
              style: TextStyle(
                fontSize: 12,
                color: os.previsaoEntrega != null &&
                        os.previsaoEntrega!.isBefore(DateTime.now())
                    ? AppColors.danger
                    : AppColors.ink2,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
}

// ── equipe do dia ─────────────────────────────────────────────────────────────

class _EquipeCard extends StatelessWidget {
  const _EquipeCard({required this.painel});
  final PainelOperacional painel;

  @override
  Widget build(BuildContext context) {
    final ativos = painel.equipe.where((m) => m.ativo).length;
    final total = painel.equipe.length;

    return SectionCard(
      title: 'Equipe de hoje',
      subtitle: '$ativos / $total ativos',
      child: Column(
        children: painel.equipe.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Sem equipe cadastrada',
                        style:
                            TextStyle(color: AppColors.ink2, fontSize: 13)),
                  ),
                )
              ]
            : painel.equipe
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              GamaAvatar(
                                initials: m.nome
                                    .trim()
                                    .split(' ')
                                    .where((p) => p.isNotEmpty)
                                    .take(2)
                                    .map((p) => p[0])
                                    .join(),
                                size: 32,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: m.ativo
                                        ? AppColors.ok
                                        : AppColors.ink3,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.surface,
                                        width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.nome,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                                Text(m.cargoLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.ink2,
                                    )),
                              ],
                            ),
                          ),
                          Text(
                            '${m.osHoje} OS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: m.osHoje > 0
                                  ? AppColors.ink
                                  : AppColors.ink3,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
      ),
    );
  }
}

// ── estoque crítico ───────────────────────────────────────────────────────────

class _EstoqueCriticoCard extends StatelessWidget {
  const _EstoqueCriticoCard({required this.painel});
  final PainelOperacional painel;

  @override
  Widget build(BuildContext context) {
    final produtos = painel.produtosCriticos;

    return SectionCard(
      title: 'Estoque crítico',
      subtitle: produtos.isEmpty ? 'Tudo ok' : '${produtos.length} itens',
      action: produtos.isEmpty
          ? null
          : TextButton(
              onPressed: () => context.go(AppRoutes.estoque),
              child: const Text('Ver estoque',
                  style:
                      TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
      child: produtos.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Nenhum produto crítico',
                    style:
                        TextStyle(color: AppColors.ink2, fontSize: 13)),
              ),
            )
          : Column(
              children: produtos
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: AppColors.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(p.nome,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                      overflow: TextOverflow.ellipsis),
                                  Text(p.codigo,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.ink3,
                                        fontFamily: 'JetBrains Mono',
                                      )),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${p.quantidadeAtual.toStringAsFixed(0)} / '
                                '${p.quantidadeMinima.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
