import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../domain/estoque.dart';
import 'estoque_notifier.dart';

String _fmtMoeda(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'R\$ $intPart,${parts[1]}';
}

const _categorias = [
  'Freios', 'Filtros', 'Lubrificantes', 'Ignicao',
  'Motor', 'Suspensao', 'Eletrica', 'Outros',
];

const _categoriasLabel = {
  'Freios': 'Freios', 'Filtros': 'Filtros', 'Lubrificantes': 'Lubrific.',
  'Ignicao': 'Ignição', 'Motor': 'Motor', 'Suspensao': 'Suspensão',
  'Eletrica': 'Elétrica', 'Outros': 'Outros',
};

enum _Ordem { qtdCrescente, qtdDecrescente, nome, ultimaEntrada }

const _ordemLabel = {
  _Ordem.qtdCrescente:  'QTD CRESCENTE',
  _Ordem.qtdDecrescente: 'QTD DECRESCENTE',
  _Ordem.nome:          'NOME A-Z',
  _Ordem.ultimaEntrada: 'ÚLTIMA ENTRADA',
};

class EstoqueScreen extends ConsumerStatefulWidget {
  const EstoqueScreen({super.key});

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen>
    with TopBarSlotMixin<EstoqueScreen> {
  final _searchController = TextEditingController();
  String? _statusFiltro;
  String? _categoriaFiltro;
  int? _fornecedorFiltro;
  _Ordem _ordem = _Ordem.qtdCrescente;

  void _syncTopBar([ResumoEstoque? r]) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final oficinaNome = auth?.availableOficinas
        .cast<dynamic>()
        .firstWhere((o) => o.id == auth.oficinaId, orElse: () => null)
        ?.nome as String?;

    setTopBarSlot(TopBarSlot(
      pageTitle: 'Estoque',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: oficinaNome?.toUpperCase(),
      desktopSubtitle: r != null ? '${r.totalSkus} SKUs' : null,
      // Search only in topbar on desktop
      searchController: isMobile ? null : _searchController,
      searchHint: isMobile ? null : 'Buscar por nome, código, categoria…',
      onSearchChanged: isMobile ? null : (v) => _aplicarFiltro(busca: v),
      action: isMobile
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: const Text('Importar planilha'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _abrirNovoProduto,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nova entrada'),
                ),
              ],
            ),
      mobileAction: IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leitor de QR Code será implementado em breve.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.qr_code_scanner_outlined),
        color: Colors.white,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Escanear QR',
      ),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTopBar();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchController.dispose());
  }

  void _abrirNovoProduto() => context.go('/estoque/produto/novo');

  void _aplicarFiltro({String? status, String? categoria, int? fornecedorId, String? busca}) {
    final notifier = ref.read(produtosNotifierProvider.notifier);
    final f = notifier.filtro;
    notifier.aplicarFiltro(f.copyWith(
      status:      status      == '__clear__' ? null : (status      ?? f.status),
      categoria:   categoria   == '__clear__' ? null : (categoria   ?? f.categoria),
      fornecedorId: fornecedorId == -1        ? null : (fornecedorId ?? f.fornecedorId),
      busca: busca ?? f.busca,
    ));
  }

  List<ProdutoListagem> _ordenar(List<ProdutoListagem> lista) {
    final out = [...lista];
    switch (_ordem) {
      case _Ordem.qtdCrescente:
        out.sort((a, b) => a.quantidadeAtual.compareTo(b.quantidadeAtual));
      case _Ordem.qtdDecrescente:
        out.sort((a, b) => b.quantidadeAtual.compareTo(a.quantidadeAtual));
      case _Ordem.nome:
        out.sort((a, b) => a.nome.compareTo(b.nome));
      case _Ordem.ultimaEntrada:
        out.sort((a, b) {
          if (a.ultimaEntradaEm == null) return 1;
          if (b.ultimaEntradaEm == null) return -1;
          return b.ultimaEntradaEm!.compareTo(a.ultimaEntradaEm!);
        });
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final asyncResumo = ref.watch(resumoEstoqueProvider);
    final asyncProdutos = ref.watch(produtosNotifierProvider);
    final asyncFornecedores = ref.watch(fornecedoresEstoqueProvider);

    asyncResumo.whenData((r) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncTopBar(r);
      });
    });

    if (isMobile) {
      return _buildMobile(asyncResumo, asyncProdutos);
    }

    return _buildDesktop(asyncResumo, asyncProdutos, asyncFornecedores);
  }

  // ─── Desktop ──────────────────────────────────────────────────────────────

  Widget _buildDesktop(
    AsyncValue<ResumoEstoque> asyncResumo,
    AsyncValue<List<ProdutoListagem>> asyncProdutos,
    AsyncValue<List<FornecedorEstoque>> asyncFornecedores,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: asyncResumo.when(
              loading: () => const SizedBox(height: 92, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SizedBox.shrink(),
              data: (r) => _DesktopKpiRow(resumo: r),
            ),
          ),

          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _DesktopFilterBar(
              statusFiltro: _statusFiltro,
              categoriaFiltro: _categoriaFiltro,
              fornecedorFiltro: _fornecedorFiltro,
              ordem: _ordem,
              produtos: asyncProdutos.valueOrNull ?? [],
              fornecedores: asyncFornecedores.valueOrNull ?? [],
              onStatusChanged: (v) => setState(() {
                _statusFiltro = v;
                _aplicarFiltro(status: v ?? '__clear__');
              }),
              onCategoriaChanged: (v) => setState(() {
                _categoriaFiltro = v;
                _aplicarFiltro(categoria: v ?? '__clear__');
              }),
              onFornecedorChanged: (v) => setState(() {
                _fornecedorFiltro = v;
                _aplicarFiltro(fornecedorId: v ?? -1);
              }),
              onOrdemChanged: (v) => setState(() => _ordem = v),
            ),
          ),

          const SizedBox(height: 16),

          // Table — card com mesmas margens dos KPI cards
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SectionCard(
              child: asyncProdutos.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.ink2),
                        const SizedBox(height: 12),
                        const Text('Erro ao carregar produtos', style: TextStyle(color: AppColors.ink2)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => ref.read(produtosNotifierProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (produtos) {
                  if (produtos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.line),
                            SizedBox(height: 16),
                            Text('Nenhum produto encontrado',
                                style: TextStyle(fontSize: 16, color: AppColors.ink2)),
                          ],
                        ),
                      ),
                    );
                  }
                  final sorted = _ordenar(produtos);
                  return _DesktopTable(
                    produtos: sorted,
                    onTap: (p) => context.go('/estoque/produto/${p.id}', extra: p),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mobile ───────────────────────────────────────────────────────────────

  Widget _buildMobile(
    AsyncValue<ResumoEstoque> asyncResumo,
    AsyncValue<List<ProdutoListagem>> asyncProdutos,
  ) {
    final resumo = asyncResumo.valueOrNull;
    final allProdutos = asyncProdutos.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Search bar below the dark topbar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _MobileSearchField(
              controller: _searchController,
              onChanged: (v) => _aplicarFiltro(busca: v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(resumoEstoqueProvider);
                await ref.read(produtosNotifierProvider.notifier).refresh();
              },
              child: CustomScrollView(
                slivers: [
                  // KPI 2-col grid
                  SliverToBoxAdapter(
                    child: asyncResumo.when(
                      loading: () => const SizedBox(
                          height: 100, child: Center(child: CircularProgressIndicator())),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (r) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                label: 'VALOR EM ESTOQUE',
                                value: _fmtMoeda(r.totalEmEstoque),
                                subtitle: '${r.totalSkus} SKUs · ${r.totalUnidades} un.',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _KpiCard(
                                label: 'CRÍTICOS',
                                value: r.itensCriticos.toString(),
                                subtitle: 'abaixo do mínimo',
                                valueColor: r.itensCriticos > 0 ? AppColors.danger : AppColors.ok,
                                dot: r.itensCriticos > 0,
                                dotColor: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Filter chips
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Row(
                        children: [
                          _StatusChip(
                            label: 'Todos ${allProdutos.length}',
                            value: null,
                            selected: _statusFiltro == null && _categoriaFiltro == null,
                            darkFill: true,
                            onTap: () => setState(() {
                              _statusFiltro = null;
                              _categoriaFiltro = null;
                              _aplicarFiltro(status: '__clear__', categoria: '__clear__');
                            }),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Críticos ${allProdutos.where((p) => p.status == 'Critico').length}',
                            value: 'Critico',
                            selected: _statusFiltro == 'Critico',
                            color: AppColors.danger,
                            onTap: () => setState(() {
                              _statusFiltro = _statusFiltro == 'Critico' ? null : 'Critico';
                              _categoriaFiltro = null;
                              _aplicarFiltro(
                                  status: _statusFiltro ?? '__clear__', categoria: '__clear__');
                            }),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Baixo ${allProdutos.where((p) => p.status == 'Baixo').length}',
                            value: 'Baixo',
                            selected: _statusFiltro == 'Baixo',
                            color: AppColors.warn,
                            onTap: () => setState(() {
                              _statusFiltro = _statusFiltro == 'Baixo' ? null : 'Baixo';
                              _categoriaFiltro = null;
                              _aplicarFiltro(
                                  status: _statusFiltro ?? '__clear__', categoria: '__clear__');
                            }),
                          ),
                          // Category chips from products in stock
                          ..._categoriasComItens(allProdutos).map((cat) {
                            final count = allProdutos.where((p) => p.categoria == cat).length;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _StatusChip(
                                label: '${_categoriasLabel[cat] ?? cat} $count',
                                value: cat,
                                selected: _categoriaFiltro == cat,
                                onTap: () => setState(() {
                                  _categoriaFiltro = _categoriaFiltro == cat ? null : cat;
                                  _statusFiltro = null;
                                  _aplicarFiltro(
                                      categoria: _categoriaFiltro ?? '__clear__',
                                      status: '__clear__');
                                }),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Critical alert banner
                  if (resumo != null && resumo.itensCriticos > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _CriticalBanner(
                          count: resumo.itensCriticos,
                          onCotar: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cotação de compras será implementada em breve.'),
                              duration: Duration(seconds: 2),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // Products
                  asyncProdutos.when(
                    loading: () => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.ink2),
                            const SizedBox(height: 12),
                            const Text('Erro ao carregar produtos',
                                style: TextStyle(color: AppColors.ink2)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  ref.read(produtosNotifierProvider.notifier).refresh(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (produtos) {
                      if (produtos.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.line),
                                SizedBox(height: 16),
                                Text('Nenhum produto encontrado',
                                    style: TextStyle(fontSize: 16, color: AppColors.ink2)),
                              ],
                            ),
                          ),
                        );
                      }
                      final sorted = _ordenar(produtos);
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _MobileProdutoCard(
                            produto: sorted[i],
                            onTap: () =>
                                context.go('/estoque/produto/${sorted[i].id}', extra: sorted[i]),
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
              ),
            ),
          ),

          // Bottom action bar
          _MobileActionBar(onNovaEntrada: _abrirNovoProduto),
        ],
      ),
    );
  }

  List<String> _categoriasComItens(List<ProdutoListagem> produtos) {
    final seen = <String>{};
    final result = <String>[];
    for (final p in produtos) {
      if (seen.add(p.categoria)) result.add(p.categoria);
      if (result.length >= 4) break;
    }
    return result;
  }
}

// ─── Desktop: KPI row ────────────────────────────────────────────────────────

class _DesktopKpiRow extends StatelessWidget {
  const _DesktopKpiRow({required this.resumo});
  final ResumoEstoque resumo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              label: 'TOTAL EM ESTOQUE',
              value: _fmtMoeda(resumo.totalEmEstoque),
              subtitle: '${resumo.totalSkus} SKUs · ${resumo.totalUnidades} unidades',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              label: 'ITENS CRÍTICOS',
              value: resumo.itensCriticos.toString(),
              subtitle: 'abaixo do mínimo',
              valueColor: resumo.itensCriticos > 0 ? AppColors.danger : AppColors.ok,
              dot: resumo.itensCriticos > 0,
              dotColor: AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              label: 'MOVIMENTAÇÃO (7D)',
              value: '+${resumo.entradasUltimos7Dias} / −${resumo.saidasUltimos7Dias}',
              subtitle: 'entradas / saídas',
              valueColor: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              label: 'COMPRA PENDENTE',
              value: resumo.comprasPendentes.toString(),
              subtitle: 'aguardando recebimento',
              valueColor: resumo.comprasPendentes > 0 ? AppColors.warn : AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
    this.dot = false,
    this.dotColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;
  final bool dot;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
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
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                      letterSpacing: 0.5)),
              if (dot) ...[
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dotColor ?? AppColors.danger, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.ink)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.ink2)),
        ],
      ),
    );
  }
}

// ─── Desktop: filter bar ─────────────────────────────────────────────────────

class _DesktopFilterBar extends StatelessWidget {
  const _DesktopFilterBar({
    required this.statusFiltro,
    required this.categoriaFiltro,
    required this.fornecedorFiltro,
    required this.ordem,
    required this.produtos,
    required this.fornecedores,
    required this.onStatusChanged,
    required this.onCategoriaChanged,
    required this.onFornecedorChanged,
    required this.onOrdemChanged,
  });

  final String? statusFiltro;
  final String? categoriaFiltro;
  final int? fornecedorFiltro;
  final _Ordem ordem;
  final List<ProdutoListagem> produtos;
  final List<FornecedorEstoque> fornecedores;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<int?> onFornecedorChanged;
  final ValueChanged<_Ordem> onOrdemChanged;

  int _count(String? status) {
    if (status == null) return produtos.length;
    return produtos.where((p) => p.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Status chips
        _StatusChip(
          label: 'Todos ${_count(null)}',
          value: null,
          selected: statusFiltro == null,
          onTap: () => onStatusChanged(null),
        ),
        const SizedBox(width: 6),
        _StatusChip(
          label: 'Críticos ${_count('Critico')}',
          value: 'Critico',
          selected: statusFiltro == 'Critico',
          color: AppColors.danger,
          onTap: () => onStatusChanged(statusFiltro == 'Critico' ? null : 'Critico'),
        ),
        const SizedBox(width: 6),
        _StatusChip(
          label: 'Baixo ${_count('Baixo')}',
          value: 'Baixo',
          selected: statusFiltro == 'Baixo',
          color: AppColors.warn,
          onTap: () => onStatusChanged(statusFiltro == 'Baixo' ? null : 'Baixo'),
        ),
        const SizedBox(width: 6),
        _StatusChip(
          label: 'OK ${_count('Ok')}',
          value: 'Ok',
          selected: statusFiltro == 'Ok',
          color: AppColors.ok,
          onTap: () => onStatusChanged(statusFiltro == 'Ok' ? null : 'Ok'),
        ),
        const SizedBox(width: 16),
        // Dropdowns
        _FilterDropdown<String?>(
          label: 'Categoria',
          value: categoriaFiltro,
          displayValue: categoriaFiltro == null ? 'Todas' : (_categoriasLabel[categoriaFiltro] ?? categoriaFiltro!),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            ..._categorias.map((c) => DropdownMenuItem(value: c, child: Text(_categoriasLabel[c] ?? c))),
          ],
          onChanged: onCategoriaChanged,
        ),
        const SizedBox(width: 8),
        if (fornecedores.isNotEmpty)
          _FilterDropdown<int?>(
            label: 'Fornecedor',
            value: fornecedorFiltro,
            displayValue: fornecedorFiltro == null
                ? 'Qualquer'
                : fornecedores.firstWhere((f) => f.id == fornecedorFiltro, orElse: () => FornecedorEstoque(id: -1, nome: '?')).nome,
            items: [
              const DropdownMenuItem(value: null, child: Text('Qualquer')),
              ...fornecedores.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nome))),
            ],
            onChanged: onFornecedorChanged,
          ),
        const Spacer(),
        // Sort
        GestureDetector(
          onTapDown: (d) async {
            final result = await showMenu<_Ordem>(
              context: context,
              position: RelativeRect.fromLTRB(
                  d.globalPosition.dx - 180, d.globalPosition.dy, d.globalPosition.dx, d.globalPosition.dy + 40),
              items: _Ordem.values.map((o) => PopupMenuItem(
                    value: o,
                    child: Text(_ordemLabel[o]!, style: const TextStyle(fontSize: 13)),
                  )).toList(),
            );
            if (result != null) onOrdemChanged(result);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ORDENAR: ',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.ink2, letterSpacing: 0.3)),
              Text(_ordemLabel[ordem]!,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: 0.3)),
              const SizedBox(width: 4),
              const Icon(Icons.unfold_more, size: 14, color: AppColors.ink2),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Desktop: table ───────────────────────────────────────────────────────────

const _kColCodigo     = 110.0;
const _kColCategoria  = 100.0;
const _kColQtd        = 64.0;
const _kColMin        = 56.0;
const _kColPreco      = 96.0;
const _kColUltEnt     = 88.0;
const _kColMenu       = 40.0;

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.produtos, required this.onTap});
  final List<ProdutoListagem> produtos;
  final ValueChanged<ProdutoListagem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TableHeader(),
        const Divider(height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: produtos.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 24, endIndent: 24),
          itemBuilder: (_, i) => _DesktopProdutoRow(
            produto: produtos[i],
            onTap: () => onTap(produtos[i]),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink2, letterSpacing: 0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
      height: 40,
      child: Row(
        children: [
          const Expanded(child: Text('PEÇA', style: style)),
          SizedBox(width: _kColCodigo,    child: const Text('CÓDIGO',     style: style)),
          SizedBox(width: _kColCategoria, child: const Text('CATEGORIA',  style: style)),
          SizedBox(width: _kColQtd,       child: const Text('QTD',        style: style, textAlign: TextAlign.center)),
          SizedBox(width: _kColMin,       child: const Text('MÍN',        style: style, textAlign: TextAlign.center)),
          SizedBox(width: _kColPreco,     child: const Text('PREÇO UN.',  style: style, textAlign: TextAlign.right)),
          SizedBox(width: _kColUltEnt,    child: const Text('ÚLTIMA ENT.', style: style, textAlign: TextAlign.right)),
          SizedBox(width: _kColMenu),
        ],
      ),
      ),
    );
  }
}

class _DesktopProdutoRow extends StatelessWidget {
  const _DesktopProdutoRow({required this.produto, required this.onTap});
  final ProdutoListagem produto;
  final VoidCallback onTap;

  Color get _qtdColor => switch (produto.status) {
        'Critico' => AppColors.danger,
        'Baixo'   => AppColors.warn,
        _         => AppColors.ok,
      };

  Color get _qtdBg => switch (produto.status) {
        'Critico' => AppColors.dangerSoft,
        'Baixo'   => AppColors.warnSoft,
        _         => AppColors.okSoft,
      };

  String get _ultimaEntrada {
    if (produto.ultimaEntradaEm == null) return '—';
    final d = produto.ultimaEntradaEm!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final qtdStr = produto.quantidadeAtual % 1 == 0
        ? produto.quantidadeAtual.toInt().toString()
        : produto.quantidadeAtual.toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.surface2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              // PEÇA: nome + unidade
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produto.nome,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    Text(
                      'Unidade: ${produto.unidade == 'Unidade' ? 'un' : produto.unidade.toLowerCase()}',
                      style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              // CÓDIGO
              SizedBox(
                width: _kColCodigo,
                child: Text(produto.codigo,
                    style: const TextStyle(
                        fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.ink2)),
              ),
              // CATEGORIA
              SizedBox(
                width: _kColCategoria,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    _categoriasLabel[produto.categoria] ?? produto.categoria,
                    style: const TextStyle(fontSize: 11, color: AppColors.ink2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // QTD badge
              SizedBox(
                width: _kColQtd,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _qtdBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      qtdStr,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: _qtdColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // MÍN
              SizedBox(
                width: _kColMin,
                child: Text(
                  produto.quantidadeMinima.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                  textAlign: TextAlign.center,
                ),
              ),
              // PREÇO UN.
              SizedBox(
                width: _kColPreco,
                child: Text(
                  _fmtMoeda(produto.precoVenda),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                  textAlign: TextAlign.right,
                ),
              ),
              // ÚLTIMA ENT.
              SizedBox(
                width: _kColUltEnt,
                child: Text(
                  _ultimaEntrada,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                  textAlign: TextAlign.right,
                ),
              ),
              // Menu
              SizedBox(
                width: _kColMenu,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  color: AppColors.ink2,
                  onPressed: () => onTap(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Ver produto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile: search field ─────────────────────────────────────────────────────

class _MobileSearchField extends StatelessWidget {
  const _MobileSearchField({this.controller, this.onChanged});
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, size: 17, color: AppColors.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, código…',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.ink3),
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
    );
  }
}

// ─── Shared filter widgets ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color,
    this.darkFill = false,
  });

  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool darkFill;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.accent;
    final bg = selected
        ? (darkFill ? AppColors.ink : activeColor.withValues(alpha: 0.1))
        : AppColors.surface;
    final textColor = selected
        ? (darkFill ? Colors.white : activeColor)
        : AppColors.ink2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? (darkFill ? AppColors.ink : activeColor) : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}


class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final String displayValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.accent : AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink2)),
          style: const TextStyle(fontSize: 13, color: AppColors.ink),
          icon: Icon(Icons.expand_more, size: 16,
              color: active ? AppColors.accent : AppColors.ink2),
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Mobile: critical banner ──────────────────────────────────────────────────

class _CriticalBanner extends StatelessWidget {
  const _CriticalBanner({required this.count, required this.onCotar});
  final int count;
  final VoidCallback onCotar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'item' : 'itens'} abaixo do mínimo',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger),
                ),
                const Text(
                  'Risco de quebra em OS',
                  style: TextStyle(fontSize: 11, color: AppColors.danger),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCotar,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cotar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile: product card ─────────────────────────────────────────────────────

class _MobileProdutoCard extends StatelessWidget {
  const _MobileProdutoCard({required this.produto, required this.onTap});
  final ProdutoListagem produto;
  final VoidCallback onTap;

  Color get _qtdColor => switch (produto.status) {
        'Critico' => AppColors.danger,
        'Baixo'   => AppColors.warn,
        _         => AppColors.ok,
      };

  Color get _qtdBg => switch (produto.status) {
        'Critico' => AppColors.dangerSoft,
        'Baixo'   => AppColors.warnSoft,
        _         => AppColors.okSoft,
      };

  @override
  Widget build(BuildContext context) {
    final qtdStr = produto.quantidadeAtual % 1 == 0
        ? produto.quantidadeAtual.toInt().toString()
        : produto.quantidadeAtual.toStringAsFixed(1);
    final minStr = produto.quantidadeMinima.toStringAsFixed(0);
    final unLabel = produto.unidade == 'Unidade'
        ? 'un'
        : produto.unidade.toLowerCase().substring(0, 2);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              // Qty badge
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: _qtdBg, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      qtdStr,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: _qtdColor),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'MIN $minStr',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _qtdColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produto.nome,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(produto.codigo,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.ink2, fontFamily: 'JetBrains Mono')),
                        const SizedBox(width: 6),
                        const Text('·', style: TextStyle(color: AppColors.ink3)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            _categoriasLabel[produto.categoria] ?? produto.categoria,
                            style: const TextStyle(fontSize: 10, color: AppColors.ink2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'R\$ ${produto.precoVenda.toStringAsFixed(2).replaceAll('.', ',')} / $unLabel',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile: bottom action bar ────────────────────────────────────────────────

class _MobileActionBar extends StatelessWidget {
  const _MobileActionBar({required this.onNovaEntrada});
  final VoidCallback onNovaEntrada;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      child: FilledButton.icon(
        onPressed: onNovaEntrada,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Nova entrada'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
    );
  }
}
