import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/estoque.dart';
import 'estoque_notifier.dart';
import 'novo_produto_screen.dart';
import 'nova_movimentacao_screen.dart';
import 'produto_detalhe_screen.dart';

const _categorias = [
  'Freios', 'Filtros', 'Lubrificantes', 'Ignicao',
  'Motor', 'Suspensao', 'Eletrica', 'Outros',
];

const _categoriasLabel = {
  'Freios': 'Freios', 'Filtros': 'Filtros', 'Lubrificantes': 'Lubrific.',
  'Ignicao': 'Ignição', 'Motor': 'Motor', 'Suspensao': 'Suspensão',
  'Eletrica': 'Elétrica', 'Outros': 'Outros',
};

class EstoqueScreen extends ConsumerStatefulWidget {
  const EstoqueScreen({super.key});

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen> {
  final _searchController = TextEditingController();
  String? _statusFiltro; // null = Todos
  String? _categoriaFiltro;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _aplicarFiltro({String? status, String? categoria, String? busca}) {
    final notifier = ref.read(produtosNotifierProvider.notifier);
    final filtroAtual = notifier.filtro;
    notifier.aplicarFiltro(filtroAtual.copyWith(
      status: status == '__clear__' ? null : (status ?? filtroAtual.status),
      categoria: categoria == '__clear__' ? null : (categoria ?? filtroAtual.categoria),
      busca: busca ?? filtroAtual.busca,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final asyncResumo = ref.watch(resumoEstoqueProvider);
    final asyncProdutos = ref.watch(produtosNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resumoEstoqueProvider);
          await ref.read(produtosNotifierProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Cards de resumo
            SliverToBoxAdapter(
              child: asyncResumo.when(
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
                data: (r) => _ResumoCards(resumo: r),
              ),
            ),

            // Barra de busca
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Buscar por nome ou código...',
                  leading: const Icon(Icons.search, size: 20),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _aplicarFiltro(busca: '');
                        },
                      ),
                  ],
                  onChanged: (v) => _aplicarFiltro(busca: v),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(Colors.white),
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: AppColors.border),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),

            // Filtros de status
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _StatusChip(label: 'Todos', value: null, selected: _statusFiltro == null,
                      onTap: () => setState(() { _statusFiltro = null; _aplicarFiltro(status: '__clear__'); })),
                    const SizedBox(width: 8),
                    _StatusChip(label: 'Crítico', value: 'Critico', selected: _statusFiltro == 'Critico',
                      color: AppColors.error,
                      onTap: () => setState(() { _statusFiltro = 'Critico'; _aplicarFiltro(status: 'Critico'); })),
                    const SizedBox(width: 8),
                    _StatusChip(label: 'Baixo', value: 'Baixo', selected: _statusFiltro == 'Baixo',
                      color: AppColors.warning,
                      onTap: () => setState(() { _statusFiltro = 'Baixo'; _aplicarFiltro(status: 'Baixo'); })),
                    const SizedBox(width: 8),
                    _StatusChip(label: 'OK', value: 'Ok', selected: _statusFiltro == 'Ok',
                      color: AppColors.success,
                      onTap: () => setState(() { _statusFiltro = 'Ok'; _aplicarFiltro(status: 'Ok'); })),
                    const SizedBox(width: 16),
                    // Filtro categoria
                    _CategoriaDropdown(
                      value: _categoriaFiltro,
                      onChanged: (v) => setState(() {
                        _categoriaFiltro = v;
                        _aplicarFiltro(categoria: v ?? '__clear__');
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de produtos
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            asyncProdutos.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text('Erro ao carregar produtos',
                          style: TextStyle(color: AppColors.textSecondary)),
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
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.border),
                          SizedBox(height: 16),
                          Text('Nenhum produto encontrado',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: produtos.length,
                  separatorBuilder: (context, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) => _ProdutoTile(
                    produto: produtos[i],
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProdutoDetalheScreen(produto: produtos[i]),
                      ));
                      ref.read(produtosNotifierProvider.notifier).refresh();
                    },
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NovoProdutoScreen()),
          );
          ref.invalidate(resumoEstoqueProvider);
          ref.read(produtosNotifierProvider.notifier).refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Cards de resumo ─────────────────────────────────────────────────────────

class _ResumoCards extends StatelessWidget {
  const _ResumoCards({required this.resumo});
  final ResumoEstoque resumo;

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _ResumoCard(
            label: 'TOTAL EM ESTOQUE',
            value: _fmt(resumo.totalEmEstoque),
            subtitle: '${resumo.totalSkus} SKUs · ${resumo.totalUnidades} unidades',
            valueColor: AppColors.textPrimary,
          ),
          const SizedBox(width: 10),
          _ResumoCard(
            label: 'ITENS CRÍTICOS',
            value: resumo.itensCriticos.toString(),
            subtitle: 'abaixo do mínimo',
            valueColor: resumo.itensCriticos > 0 ? AppColors.error : AppColors.success,
            dot: resumo.itensCriticos > 0,
          ),
          const SizedBox(width: 10),
          _ResumoCard(
            label: 'MOVIMENTAÇÃO (7D)',
            value: '+${resumo.entradasUltimos7Dias} / −${resumo.saidasUltimos7Dias}',
            subtitle: 'entradas / saídas',
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.valueColor,
    this.dot = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color valueColor;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
              if (dot) ...[
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Chips de filtro ─────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoriaDropdown extends StatelessWidget {
  const _CategoriaDropdown({required this.value, required this.onChanged});
  final String? value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: value != null ? AppColors.primary.withAlpha(15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text('Categoria',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          icon: Icon(Icons.expand_more,
              size: 16,
              color: value != null ? AppColors.primary : AppColors.textSecondary),
          isDense: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            ..._categorias.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(_categoriasLabel[c] ?? c),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Tile de produto ─────────────────────────────────────────────────────────

class _ProdutoTile extends StatelessWidget {
  const _ProdutoTile({required this.produto, required this.onTap});
  final ProdutoListagem produto;
  final VoidCallback onTap;

  Color get _qtdColor => switch (produto.status) {
        'Critico' => AppColors.error,
        'Baixo' => AppColors.warning,
        _ => AppColors.success,
      };

  Color get _qtdBg => switch (produto.status) {
        'Critico' => AppColors.errorLight,
        'Baixo' => AppColors.warningLight,
        _ => AppColors.successLight,
      };

  String get _ultimaEntrada {
    if (produto.ultimaEntradaEm == null) return '—';
    final d = produto.ultimaEntradaEm!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Quantidade badge
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _qtdBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    produto.quantidadeAtual % 1 == 0
                        ? produto.quantidadeAtual.toInt().toString()
                        : produto.quantidadeAtual.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _qtdColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    produto.unidade == 'Unidade' ? 'un' : produto.unidade.toLowerCase().substring(0, 2),
                    style: TextStyle(fontSize: 9, color: _qtdColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Nome + código + categoria
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(produto.codigo,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace')),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _categoriasLabel[produto.categoria] ?? produto.categoria,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Preço + última entrada
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(produto.precoVenda),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Mín: ${produto.quantidadeMinima.toStringAsFixed(0)} · $_ultimaEntrada',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
