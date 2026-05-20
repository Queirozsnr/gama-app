import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../data/estoque_remote_data_source.dart';
import '../domain/estoque.dart';
import 'estoque_notifier.dart';
import 'nova_movimentacao_screen.dart';

const _categoriasLabel = {
  'Freios': 'Freios', 'Filtros': 'Filtros', 'Lubrificantes': 'Lubrificantes',
  'Ignicao': 'Ignição', 'Motor': 'Motor', 'Suspensao': 'Suspensão',
  'Eletrica': 'Elétrica', 'Outros': 'Outros',
};

class ProdutoDetalheScreen extends ConsumerWidget {
  const ProdutoDetalheScreen({super.key, required this.produto});
  final ProdutoListagem produto;

  Color get _statusColor => switch (produto.status) {
        'Critico' => AppColors.error,
        'Baixo' => AppColors.warning,
        _ => AppColors.success,
      };

  Color get _statusBg => switch (produto.status) {
        'Critico' => AppColors.errorLight,
        'Baixo' => AppColors.warningLight,
        _ => AppColors.successLight,
      };

  String get _statusLabel => switch (produto.status) {
        'Critico' => 'Crítico',
        'Baixo' => 'Baixo',
        _ => 'OK',
      };

  String _fmt(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMovs = ref.watch(movimentacoesProvider(produto.id));

    return TopBarSlotProvider(
      slot: TopBarSlot(
        pageTitle: produto.nome,
        mobileStyle: MobileTopBarStyle.dark,
        mobileSubtitle: (_categoriasLabel[produto.categoria] ?? produto.categoria).toUpperCase(),
        leading: BackButton(onPressed: () => context.go('/estoque')),
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context.go(
                '/estoque/produto/${produto.id}/editar',
                extra: produto,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Excluir',
              onPressed: () => _confirmarExclusao(context, ref),
            ),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Info card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(produto.nome,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(produto.codigo,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.ink2,
                                        fontFamily: 'JetBrains Mono')),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Text(
                                    _categoriasLabel[produto.categoria] ?? produto.categoria,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.ink2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_statusLabel,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoCol('Qtd. atual',
                          '${produto.quantidadeAtual.toStringAsFixed(0)} ${produto.unidade == 'Unidade' ? 'un' : produto.unidade}',
                          color: _statusColor),
                      _vDivider(),
                      _InfoCol('Qtd. mínima',
                          produto.quantidadeMinima.toStringAsFixed(0)),
                      _vDivider(),
                      _InfoCol('Preço venda', _fmt(produto.precoVenda)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Botões de ação
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _abrirMovimentacao(context, ref, 'Entrada'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Entrada'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _abrirMovimentacao(context, ref, 'Saida'),
                      icon: const Icon(Icons.remove, size: 18),
                      label: const Text('Saída'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _abrirMovimentacao(context, ref, 'Ajuste'),
                    child: const Text('Ajuste'),
                  ),
                ],
              ),
            ),
          ),

          // Histórico
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('MOVIMENTAÇÕES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                      letterSpacing: 0.8)),
            ),
          ),

          asyncMovs.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Center(
                child: Text('Erro ao carregar movimentações',
                    style: TextStyle(color: AppColors.ink2)),
              ),
            ),
            data: (movs) {
              if (movs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Nenhuma movimentação registrada',
                          style: TextStyle(color: AppColors.ink2)),
                    ),
                  ),
                );
              }
              return SliverList.separated(
                itemCount: movs.length,
                separatorBuilder: (context, _) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) => _MovimentacaoTile(mov: movs[i]),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 36, color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 12));

  Future<void> _abrirMovimentacao(
      BuildContext context, WidgetRef ref, String tipo) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NovaMovimentacaoScreen(produto: produto, tipoInicial: tipo),
      ),
    );
    if (ok == true) {
      ref.invalidate(movimentacoesProvider(produto.id));
      ref.read(produtosNotifierProvider.notifier).refresh();
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja excluir "${produto.nome}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(estoqueDataSourceProvider).excluirProduto(produto.id);
        if (context.mounted) {
          ref.invalidate(resumoEstoqueProvider);
          ref.read(produtosNotifierProvider.notifier).refresh();
          context.go('/estoque');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _InfoCol extends StatelessWidget {
  const _InfoCol(this.label, this.value, {this.color = AppColors.ink});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.ink2)),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _MovimentacaoTile extends StatelessWidget {
  const _MovimentacaoTile({required this.mov});
  final MovimentacaoEstoque mov;

  Color get _color => switch (mov.tipo) {
        'Entrada' => AppColors.success,
        'Saida' => AppColors.error,
        _ => AppColors.primary,
      };

  IconData get _icon => switch (mov.tipo) {
        'Entrada' => Icons.add_circle_outline,
        'Saida' => Icons.remove_circle_outline,
        _ => Icons.tune_outlined,
      };

  String get _label => switch (mov.tipo) {
        'Entrada' => '+${mov.quantidade.toStringAsFixed(0)}',
        'Saida' => '−${mov.quantidade.toStringAsFixed(0)}',
        _ => '=${mov.quantidade.toStringAsFixed(0)}',
      };

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mov.fornecedorNome ?? mov.observacao ?? mov.tipo,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(_date(mov.criadoEm),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.ink2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_label,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _color)),
              if (mov.precoUnitario != null)
                Text(
                    'R\$ ${mov.precoUnitario!.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}
