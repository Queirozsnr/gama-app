import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/filter_tab_bar.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/chips/payment_badge.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../funcionarios/domain/remuneracao.dart';
import '../domain/pagamento.dart';
import 'acompanhamento_socio_screen.dart';
import 'historico_pagamentos_screen.dart';
import 'novo_pagamento_screen.dart';
import 'pagamento_detalhe_screen.dart';
import 'pagamentos_notifier.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

String _mesAno(DateTime d) {
  const meses = [
    '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];
  return '${meses[d.month].toUpperCase()}/${d.year}';
}

enum _StatusPag { aPagar, pendente, pago, apuracao, semDados }

double _totalComissao(AsyncValue<List<OsAberta>> osAsync, FuncionarioAcumulado f) =>
    osAsync.whenOrNull(
      data: (osList) => osList.fold<double>(0.0, (s, os) => s + os.valorContribuicao),
    ) ?? f.valorAcumulado;

bool _pagoEsteMes(FuncionarioAcumulado f) {
  final u = f.ultimoPagamentoEm;
  if (u == null) return false;
  final now = DateTime.now();
  return u.month == now.month && u.year == now.year;
}

String _fmtDia(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

_StatusPag _statusOf(FuncionarioAcumulado f) {
  if (f.tipoRemuneracao == 'Socio') return _StatusPag.apuracao;
  if (f.pagamentoPendenteId != null) return _StatusPag.pendente;
  if (f.valorAcumulado > 0) return _StatusPag.aPagar;
  if (f.ultimoPagamentoEm != null) return _StatusPag.pago;
  return _StatusPag.semDados;
}

// ─── screen ───────────────────────────────────────────────────────────────────

class PagamentosScreen extends ConsumerStatefulWidget {
  const PagamentosScreen({super.key});

  @override
  ConsumerState<PagamentosScreen> createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends ConsumerState<PagamentosScreen>
    with TopBarSlotMixin<PagamentosScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _searchOpen = false;
  int _filtroIdx = 0; // 0=todos 1=comissionados 2=salario 3=gerentes
  String _filtroStatus = 'todos'; // 'todos' | 'a_pagar' | 'pago'
  FuncionarioAcumulado? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTopBar();
  }

  void _syncTopBar() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final token = auth?.token ?? '';
    final oficinaNome = auth?.availableOficinas
        .cast<dynamic>()
        .firstWhere((o) => o.id == auth.oficinaId, orElse: () => null)
        ?.nome as String?;
    final mes = _mesAno(DateTime.now());

    if (!JwtDecoder.isGestor(token)) {
      setTopBarSlot(TopBarSlot(
        pageTitle: 'Meus pagamentos',
        mobileStyle: MobileTopBarStyle.dark,
        mobileSubtitle: oficinaNome != null ? '• $oficinaNome' : null,
        desktopSubtitle: oficinaNome != null ? '$mes · ${oficinaNome.toUpperCase()}' : mes,
      ));
      return;
    }

    setTopBarSlot(TopBarSlot(
      pageTitle: 'Pagamento da equipe',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: oficinaNome != null ? '• $oficinaNome' : null,
      desktopSubtitle: oficinaNome != null ? '$mes · ${oficinaNome.toUpperCase()}' : mes,
      searchController: isDesktop ? _searchController : null,
      searchHint: isDesktop ? 'Buscar funcionário…' : null,
      onSearchChanged: isDesktop ? (v) => setState(() => _query = v.toLowerCase()) : null,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () => GamaSnackBar.info(context, 'Exportação será implementada em breve.'),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Exportar folha'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => GamaSnackBar.info(context, 'Pagamento em lote será implementado em breve.'),
            icon: const Icon(Icons.payments_outlined, size: 16),
            label: const Text('Pagar todos'),
          ),
        ],
      ),
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
    ));
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchController.clear();
      setState(() => _query = '');
    }
    _syncTopBar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchController.dispose());
    super.dispose();
  }

  List<FuncionarioAcumulado> _filtrar(List<FuncionarioAcumulado> todos) {
    var lista = todos;
    if (_query.isNotEmpty) {
      lista = lista.where((f) => f.nome.toLowerCase().contains(_query)).toList();
    }
    lista = switch (_filtroIdx) {
      1 => lista.where((f) => f.tipoRemuneracao == 'Porcentagem').toList(),
      2 => lista.where((f) => f.tipoRemuneracao == 'Fixo').toList(),
      3 => lista.where((f) => f.tipoRemuneracao == 'Socio').toList(),
      _ => lista,
    };
    if (_filtroStatus == 'a_pagar') {
      lista = lista
          .where((f) {
            final s = _statusOf(f);
            return s == _StatusPag.aPagar || s == _StatusPag.pendente;
          })
          .toList();
    } else if (_filtroStatus == 'pago') {
      lista = lista
          .where((f) => _statusOf(f) == _StatusPag.pago)
          .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authNotifierProvider).valueOrNull?.token ?? '';
    final isGestor = JwtDecoder.isGestor(token);
    final meuId = JwtDecoder.funcionarioId(token);

    if (!isGestor && meuId != null) return _buildMecanicoView(meuId);

    final asyncData = ref.watch(pagamentosNotifierProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
            const SizedBox(height: 12),
            const Text('Erro ao carregar pagamentos',
                style: TextStyle(color: AppColors.ink2)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(pagamentosNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (todos) {
        final isDesktop = MediaQuery.sizeOf(context).width >= 800;
        return isDesktop ? _buildDesktop(todos) : _buildMobile(todos);
      },
    );
  }

  Widget _buildMecanicoView(int funcionarioId) {
    final asyncData = ref.watch(pagamentosNotifierProvider);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
            const SizedBox(height: 12),
            const Text('Erro ao carregar pagamentos',
                style: TextStyle(color: AppColors.ink2)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(pagamentosNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (todos) {
        final meu = todos.cast<FuncionarioAcumulado?>().firstWhere(
          (f) => f?.funcionarioId == funcionarioId,
          orElse: () => null,
        );
        if (meu == null) {
          return const Center(
            child: Text('Dados não encontrados.',
                style: TextStyle(color: AppColors.ink2)),
          );
        }
        return SingleChildScrollView(
          child: _DetailPanel(
            key: ValueKey(meu.funcionarioId),
            funcionario: meu,
            showActions: false,
            onPagar: () => _abrirPagamento(meu),
            onHistorico: () => _abrirHistorico(meu),
          ),
        );
      },
    );
  }

  Widget _buildDesktop(List<FuncionarioAcumulado> todos) {
    final filtrados = _filtrar(todos);

    // ── KPI derivations ──
    final semGerente = todos.where((f) => f.tipoRemuneracao != 'Socio').toList();
    final totalAPagar =
        semGerente.fold(0.0, (s, f) => s + f.valorAcumulado);
    final pendentes = semGerente.where((f) => f.pagamentoPendenteId != null).length;
    final totalComissoes = todos
        .where((f) => f.tipoRemuneracao == 'Porcentagem')
        .fold(0.0, (s, f) => s + f.valorAcumulado);
    final countComissionados =
        todos.where((f) => f.tipoRemuneracao == 'Porcentagem').length;
    final osComissionados = todos
        .where((f) => f.tipoRemuneracao == 'Porcentagem')
        .fold(0, (s, f) => s + f.osAbertasCount);
    final totalSalarios = todos
        .where((f) => f.tipoRemuneracao == 'Fixo')
        .fold(0.0, (s, f) => s + f.valorAcumulado);
    final countSalarios =
        todos.where((f) => f.tipoRemuneracao == 'Fixo').length;
    final gerente = todos.cast<FuncionarioAcumulado?>().firstWhere(
        (f) => f?.tipoRemuneracao == 'Socio',
        orElse: () => null);

    // ── filter tab labels ──
    final tabLabels = [
      'Todos ${todos.length}',
      'Comissionados $countComissionados',
      'Salário fixo $countSalarios',
      'Gerentes ${todos.where((f) => f.tipoRemuneracao == 'Socio').length}',
    ];

    // ── count summary ──
    final countPagamentos =
        todos.where((f) => f.pagamentoPendenteId != null).length;
    final countApuracao =
        todos.where((f) => f.tipoRemuneracao == 'Socio').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── KPI row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'TOTAL A PAGAR',
                  value: _fmt(totalAPagar),
                  subtitle: '$pendentes funcionários pendentes',
                  badge: 'PRONTO',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'COMISSÕES GERADAS',
                  value: _fmt(totalComissoes),
                  subtitle: '$countComissionados mecânicos · $osComissionados OS',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'SALÁRIOS FIXOS',
                  value: _fmt(totalSalarios),
                  subtitle: '$countSalarios funcionários',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'APURAÇÃO GERENTE',
                  value: _fmt(gerente?.valorAcumulado ?? 0),
                  subtitle: gerente != null
                      ? '${gerente.nome} · ${gerente.osAbertasCount} OS · Informativo'
                      : 'Nenhum gerente cadastrado',
                  badge: gerente != null ? 'INFO' : null,
                  badgeColor: AppColors.info,
                  badgeBgColor: AppColors.infoSoft,
                ),
              ),
            ],
          ),
        ),

        // ── filter row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              FilterTabBar(
                tabs: tabLabels,
                selectedIndex: _filtroIdx,
                onTabSelected: (i) => setState(() {
                  _filtroIdx = i;
                  _selected = null;
                }),
              ),
              const SizedBox(width: 16),
              _StatusDropdown(
                value: _filtroStatus,
                onChanged: (v) => setState(() {
                  _filtroStatus = v;
                  _selected = null;
                }),
              ),
              const Spacer(),
              Text(
                '$countPagamentos pagamento${countPagamentos != 1 ? 's' : ''}'
                '${countApuracao > 0 ? ' · $countApuracao apuração' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.ink2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        const Divider(height: 1),

        // ── two-column body ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee list
              SizedBox(
                width: 560,
                child: filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 48, color: AppColors.line),
                            const SizedBox(height: 12),
                            Text(
                              _query.isEmpty
                                  ? 'Nenhum funcionário neste filtro'
                                  : 'Nenhum resultado para "$_query"',
                              style: const TextStyle(color: AppColors.ink2),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(pagamentosNotifierProvider.notifier).refresh(),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: filtrados.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) => _FuncionarioRow(
                            funcionario: filtrados[i],
                            selected: _selected?.funcionarioId ==
                                filtrados[i].funcionarioId,
                            onTap: () => setState(
                                () => _selected = filtrados[i]),
                            onPagar: () => _abrirPagamento(filtrados[i]),
                          ),
                        ),
                      ),
              ),

              const VerticalDivider(width: 1),

              // Detail panel
              Expanded(
                child: _selected == null
                    ? const Center(
                        child: Text(
                          'Selecione um funcionário para ver os detalhes',
                          style: TextStyle(color: AppColors.ink2, fontSize: 13),
                        ),
                      )
                    : _DetailPanel(
                        key: ValueKey(_selected!.funcionarioId),
                        funcionario: _selected!,
                        onPagar: () => _abrirPagamento(_selected!),
                        onHistorico: () => _abrirHistorico(_selected!),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(List<FuncionarioAcumulado> todos) {
    final filtrados = _filtrar(todos);
    final semGerente = todos.where((f) => f.tipoRemuneracao != 'Socio').toList();
    final totalAPagar = semGerente.fold(0.0, (s, f) => s + f.valorAcumulado);
    final totalComissoes = todos
        .where((f) => f.tipoRemuneracao == 'Porcentagem')
        .fold(0.0, (s, f) => s + f.valorAcumulado);
    final totalSalarios = todos
        .where((f) => f.tipoRemuneracao == 'Fixo')
        .fold(0.0, (s, f) => s + f.valorAcumulado);
    final gerente = todos.cast<FuncionarioAcumulado?>()
        .firstWhere((f) => f?.tipoRemuneracao == 'Socio', orElse: () => null);
    final countComissionados = todos.where((f) => f.tipoRemuneracao == 'Porcentagem').length;
    final countSalarios = todos.where((f) => f.tipoRemuneracao == 'Fixo').length;
    final countGerentes = todos.where((f) => f.tipoRemuneracao == 'Socio').length;

    final tabLabels = [
      'Todos ${todos.length}',
      'Comissão $countComissionados',
      'Fixo $countSalarios',
      'Gerente $countGerentes',
    ];

    return Column(
      children: [
        _PagamentoDarkArea(
          totalAPagar: totalAPagar,
          totalComissoes: totalComissoes,
          totalSalarios: totalSalarios,
          gerenteValor: gerente?.valorAcumulado ?? 0,
        ),
        if (_searchOpen)
          _MobileSearchRow(
            controller: _searchController,
            hint: 'Buscar funcionário…',
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        _MobileFiltroBar(
          tabLabels: tabLabels,
          selectedIndex: _filtroIdx,
          onTabSelected: (i) => setState(() => _filtroIdx = i),
          filtroStatus: _filtroStatus,
          onStatusChanged: (v) => setState(() => _filtroStatus = v),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined, size: 48, color: AppColors.line),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty
                            ? 'Nenhum funcionário neste filtro'
                            : 'Nenhum resultado para "$_query"',
                        style: const TextStyle(color: AppColors.ink2),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(pagamentosNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        16, 12, 16, MediaQuery.paddingOf(context).bottom + 16),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PagamentoMobileCard(
                      funcionario: filtrados[i],
                      onTap: () => _abrirPagamento(filtrados[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _abrirPagamento(FuncionarioAcumulado f) async {
    if (f.tipoRemuneracao == 'Fixo' && _pagoEsteMes(f)) {
      final continuar = await GamaConfirmDialog.show(
        context,
        title: 'Pagamento duplicado',
        message:
            '${f.nome} já recebeu salário fixo em ${_fmtDia(f.ultimoPagamentoEm!)} deste mês. Deseja pagar novamente?',
        confirmLabel: 'Pagar mesmo assim',
        confirmColor: AppColors.warn,
      );
      if (!mounted || !continuar) return;
    }

    if (f.tipoRemuneracao == 'Socio') {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => AcompanhamentoSocioScreen(
          funcionarioId: f.funcionarioId,
          funcionarioNome: f.nome,
        ),
      ));
      return;
    }
    // Pendente → detalhe do pendente; Pago sem pendente → último recibo; senão → novo pagamento
    final targetId = f.pagamentoPendenteId ??
        (_statusOf(f) == _StatusPag.pago ? f.ultimoPagamentoId : null);
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
          builder: (_) => targetId != null
              ? PagamentoDetalheScreen(pagamentoId: targetId)
              : NovoPagamentoScreen(funcionario: f),
        ))
        .then((_) => ref.invalidate(pagamentosNotifierProvider));
  }

  void _abrirHistorico(FuncionarioAcumulado f) {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => HistoricoPagamentosScreen(
        funcionarioId: f.funcionarioId,
        funcionarioNome: f.nome,
      ),
    ));
  }
}

// ─── filter status dropdown ────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  String get _label => switch (value) {
        'a_pagar' => 'Status: A pagar',
        'pago'    => 'Status: Pago',
        _         => 'Status: Todos',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'todos',   child: Text('Todos')),
        PopupMenuItem(value: 'a_pagar', child: Text('A pagar')),
        PopupMenuItem(value: 'pago',    child: Text('Pago')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink2)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

// ─── employee row ──────────────────────────────────────────────────────────

class _FuncionarioRow extends StatelessWidget {
  const _FuncionarioRow({
    required this.funcionario,
    required this.selected,
    required this.onTap,
    required this.onPagar,
  });

  final FuncionarioAcumulado funcionario;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPagar;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  PaymentType get _paymentType => switch (funcionario.tipoRemuneracao) {
        'Fixo'  => PaymentType.fixo,
        'Socio' => PaymentType.socio,
        _       => PaymentType.comissao,
      };

  String get _descricao {
    final f = funcionario;
    return switch (f.tipoRemuneracao) {
      'Porcentagem' when f.porcentagem != null => () {
          final receita = f.porcentagem! > 0
              ? f.valorAcumulado * 100 / f.porcentagem!
              : 0.0;
          return '${_fmt(receita)} × ${f.porcentagem}% · ${f.osAbertasCount} OS';
        }(),
      'Fixo'  => 'Salário fixo · ${f.osAbertasCount} OS',
      'Socio' => '${_fmt(f.valorAcumulado)} · ${f.osAbertasCount} OS apuradas',
      _       => tipoRemuneracaoLabel(f.tipoRemuneracao),
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(funcionario);
    final isGerente = funcionario.tipoRemuneracao == 'Socio';

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft.withValues(alpha: 0.4) : null,
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            GamaAvatar(initials: _initials, size: 40),
            const SizedBox(width: 12),

            // Name + badge + cargo + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          funcionario.nome,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PaymentBadge(
                          type: _paymentType,
                          percent: funcionario.porcentagem),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cargoLabel(funcionario.cargo),
                    style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _descricao,
                    style: const TextStyle(fontSize: 11, color: AppColors.ink3),
                  ),
                  if (funcionario.ultimoPagamentoEm != null && funcionario.tipoRemuneracao != 'Socio') ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 11, color: AppColors.ok),
                        const SizedBox(width: 3),
                        Text(
                          'Pago em ${_fmtDia(funcionario.ultimoPagamentoEm!)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.ok),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Amount + status + action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isGerente ? 'APURAÇÃO' : 'A PAGAR',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(funcionario.valorAcumulado),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusChip(status: status),
                    const SizedBox(width: 8),
                    _ActionButton(
                        status: status,
                        isGerente: isGerente,
                        onPressed: onPagar),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── status chip ──────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _StatusPag status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _StatusPag.aPagar    => ('A PAGAR', AppColors.warnSoft, AppColors.warn),
      _StatusPag.pendente  => ('PENDENTE', AppColors.infoSoft, AppColors.info),
      _StatusPag.pago      => ('PAGO', AppColors.okSoft, AppColors.ok),
      _StatusPag.apuracao  => ('APURAÇÃO', AppColors.infoSoft, AppColors.info),
      _StatusPag.semDados  => ('SEM DADOS', AppColors.surface2, AppColors.ink3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─── action button ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.status,
      required this.isGerente,
      required this.onPressed});
  final _StatusPag status;
  final bool isGerente;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isGerente) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Ver OS →', style: TextStyle(fontSize: 12)),
      );
    }
    if (status == _StatusPag.pago) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Recibo', style: TextStyle(fontSize: 12)),
      );
    }
    if (status == _StatusPag.pendente) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.info,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Confirmar', style: TextStyle(fontSize: 12)),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Pagar', style: TextStyle(fontSize: 12)),
    );
  }
}

// ─── detail panel ─────────────────────────────────────────────────────────

class _DetailPanel extends ConsumerWidget {
  const _DetailPanel({
    super.key,
    required this.funcionario,
    required this.onPagar,
    required this.onHistorico,
    this.showActions = true,
  });

  final FuncionarioAcumulado funcionario;
  final VoidCallback onPagar;
  final VoidCallback onHistorico;
  final bool showActions;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  PaymentType get _paymentType => switch (funcionario.tipoRemuneracao) {
        'Fixo'  => PaymentType.fixo,
        'Socio' => PaymentType.socio,
        _       => PaymentType.comissao,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGerente = funcionario.tipoRemuneracao == 'Socio';
    final status = _statusOf(funcionario);

    final isComissao = funcionario.tipoRemuneracao == 'Porcentagem';
    final osAsync = isComissao
        ? ref.watch(osAbertasProvider(funcionario.funcionarioId))
        : const AsyncData<List<OsAberta>>([]);
    final totalReal = isComissao
        ? _totalComissao(osAsync, funcionario)
        : funcionario.valorAcumulado;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ──
          Row(
            children: [
              GamaAvatar(initials: _initials, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            funcionario.nome,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PaymentBadge(
                            type: _paymentType,
                            percent: funcionario.porcentagem),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cargoLabel(funcionario.cargo),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history_outlined),
                tooltip: 'Histórico',
                onPressed: onHistorico,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── breakdown ──
          isGerente
              ? _GerenteBreakdown(funcionario: funcionario)
              : _ComissaoBreakdown(funcionario: funcionario, ref: ref),

          const SizedBox(height: 20),

          // ── actions ──
          if (showActions && !isGerente) ...[
            FilledButton(
              onPressed: onPagar,
              style: FilledButton.styleFrom(
                backgroundColor: switch (status) {
                  _StatusPag.pago     => AppColors.ok,
                  _StatusPag.pendente => AppColors.info,
                  _                   => AppColors.accent,
                },
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(switch (status) {
                _StatusPag.pago     => 'Ver recibo',
                _StatusPag.pendente => 'Confirmar pagamento',
                _                   => 'Pagar ${_fmt(totalReal)}',
              }),
            ),
          ] else if (showActions) ...[
            FilledButton.icon(
              onPressed: onPagar,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver OS do gerente'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],

          // ── último pagamento ──
          if (funcionario.ultimoPagamentoEm != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                () {
                  final d = funcionario.ultimoPagamentoEm!;
                  return 'Último pagamento · ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                }(),
                style: const TextStyle(fontSize: 11, color: AppColors.ink3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── comissão breakdown ────────────────────────────────────────────────────

class _ComissaoBreakdown extends StatelessWidget {
  const _ComissaoBreakdown(
      {required this.funcionario, required this.ref});
  final FuncionarioAcumulado funcionario;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isComissao = funcionario.tipoRemuneracao == 'Porcentagem';

    final osAsync = ref.watch(osAbertasProvider(funcionario.funcionarioId));

    final totalReal = _totalComissao(osAsync, funcionario);

    final receitaServicos = isComissao && (funcionario.porcentagem ?? 0) > 0
        ? totalReal * 100 / funcionario.porcentagem!
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: isComissao ? 'Cálculo da comissão' : 'Resumo do pagamento',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              if (isComissao) ...[
                _InfoRow('OS faturadas no período',
                    '${funcionario.osAbertasCount}'),
                _InfoRow('Receita de serviços', _fmt(receitaServicos)),
                _InfoRow(
                    'Comissão sobre serviços', '${funcionario.porcentagem}%'),
              ] else ...[
                _InfoRow('Salário fixo', _fmt(funcionario.valorAcumulado)),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a pagar',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    _fmt(totalReal),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isComissao) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'OS que compõem',
            action: osAsync.whenOrNull(
              data: (os) => TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todas (${os.length})',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.accent),
                ),
              ),
            ),
            child: osAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Erro ao carregar OS',
                    style: TextStyle(color: AppColors.ink2)),
              ),
              data: (osList) {
                if (osList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma OS em aberto',
                        style: TextStyle(color: AppColors.ink2, fontSize: 13)),
                  );
                }
                final preview = osList.take(6).toList();
                return Column(
                  children: [
                    for (int i = 0; i < preview.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      _OsRow(os: preview[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ─── gerente breakdown ────────────────────────────────────────────────────

class _GerenteBreakdown extends StatelessWidget {
  const _GerenteBreakdown({required this.funcionario});
  final FuncionarioAcumulado funcionario;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Apuração do período',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          _InfoRow('OS apuradas no período',
              '${funcionario.osAbertasCount}'),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Receita líquida',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                _fmt(funcionario.valorAcumulado),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.info),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Apuração informativa — gerentes não recebem via folha.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── info row ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.ink2)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

// ─── OS row ───────────────────────────────────────────────────────────────

class _OsRow extends StatelessWidget {
  const _OsRow({required this.os});
  final OsAberta os;

  String get _data {
    final d = os.dataEntrada;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '#${os.ordemServicoId}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
                fontFamily: 'JetBrains Mono'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  os.clienteNome,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _data,
                  style: const TextStyle(fontSize: 10, color: AppColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _fmt(os.totalOS),
            style: const TextStyle(fontSize: 12, color: AppColors.ink2),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_fmt(os.valorContribuicao)}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

// ─── mobile dark area ──────────────────────────────────────────────────────────

class _PagamentoDarkArea extends StatelessWidget {
  const _PagamentoDarkArea({
    required this.totalAPagar,
    required this.totalComissoes,
    required this.totalSalarios,
    required this.gerenteValor,
  });

  final double totalAPagar;
  final double totalComissoes;
  final double totalSalarios;
  final double gerenteValor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          _MobileStatBox(value: _fmt(totalAPagar), label: 'A PAGAR', accent: true),
          _MobileStatBox(value: _fmt(totalComissoes), label: 'COMISSÕES'),
          _MobileStatBox(value: _fmt(totalSalarios), label: 'SALÁRIOS'),
          _MobileStatBox(value: _fmt(gerenteValor), label: 'GERENTE'),
        ],
      ),
    );
  }
}

class _MobileSearchRow extends StatelessWidget {
  const _MobileSearchRow({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
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
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sidebarText),
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

class _MobileStatBox extends StatelessWidget {
  const _MobileStatBox({
    required this.value,
    required this.label,
    this.accent = false,
  });
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent ? AppColors.accent : AppColors.ink,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
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

// ─── mobile filter bar ─────────────────────────────────────────────────────────

class _MobileFiltroBar extends StatelessWidget {
  const _MobileFiltroBar({
    required this.tabLabels,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.filtroStatus,
    required this.onStatusChanged,
  });

  final List<String> tabLabels;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final String filtroStatus;
  final ValueChanged<String> onStatusChanged;

  String get _statusLabel => switch (filtroStatus) {
        'a_pagar' => 'A pagar',
        'pago'    => 'Pago',
        _         => 'Todos',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: List.generate(tabLabels.length, (i) {
                final active = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onTabSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: active ? AppColors.ink : AppColors.line),
                      ),
                      child: Text(
                        tabLabels[i],
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  initialValue: filtroStatus,
                  onSelected: onStatusChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'todos',   child: Text('Todos')),
                    PopupMenuItem(value: 'a_pagar', child: Text('A pagar')),
                    PopupMenuItem(value: 'pago',    child: Text('Pago')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Status: $_statusLabel',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink2),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down,
                            size: 14, color: AppColors.ink3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── mobile payment card ───────────────────────────────────────────────────────

class _PagamentoMobileCard extends StatelessWidget {
  const _PagamentoMobileCard({
    required this.funcionario,
    required this.onTap,
  });

  final FuncionarioAcumulado funcionario;
  final VoidCallback onTap;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, parts[0].length.clamp(0, 2));
  }

  PaymentType get _paymentType => switch (funcionario.tipoRemuneracao) {
        'Fixo'  => PaymentType.fixo,
        'Socio' => PaymentType.socio,
        _       => PaymentType.comissao,
      };

  String get _descricao {
    final f = funcionario;
    return switch (f.tipoRemuneracao) {
      'Porcentagem' when f.porcentagem != null =>
          '${f.porcentagem}% · ${f.osAbertasCount} OS',
      'Fixo'  => '${f.osAbertasCount} OS no período',
      'Socio' => '${f.osAbertasCount} OS apuradas',
      _       => tipoRemuneracaoLabel(f.tipoRemuneracao),
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(funcionario);
    final isGerente = funcionario.tipoRemuneracao == 'Socio';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              GamaAvatar(initials: _initials, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            funcionario.nome,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        PaymentBadge(
                            type: _paymentType,
                            percent: funcionario.porcentagem),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cargoLabel(funcionario.cargo)} · $_descricao',
                      style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (funcionario.ultimoPagamentoEm != null && funcionario.tipoRemuneracao != 'Socio') ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 11, color: AppColors.ok),
                          const SizedBox(width: 3),
                          Text(
                            'Pago em ${_fmtDia(funcionario.ultimoPagamentoEm!)}',
                            style: const TextStyle(fontSize: 10, color: AppColors.ok),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          isGerente
                              ? 'APURAÇÃO'
                              : _fmt(funcionario.valorAcumulado),
                          style: TextStyle(
                            fontSize: isGerente ? 10 : 14,
                            fontWeight: FontWeight.w700,
                            color: isGerente ? AppColors.ink3 : AppColors.ink,
                            letterSpacing: isGerente ? 0.5 : -0.3,
                          ),
                        ),
                        if (!isGerente) ...[
                          const SizedBox(width: 6),
                          _StatusChip(status: status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
