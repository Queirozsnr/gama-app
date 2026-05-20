import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_searchable_select.dart';
import '../data/estoque_remote_data_source.dart';
import '../domain/estoque.dart';
import 'estoque_notifier.dart';

class NovaMovimentacaoScreen extends ConsumerStatefulWidget {
  const NovaMovimentacaoScreen({super.key, required this.produto, this.tipoInicial});
  final ProdutoListagem produto;
  final String? tipoInicial; // 'Entrada' | 'Saida' | 'Ajuste'

  @override
  ConsumerState<NovaMovimentacaoScreen> createState() => _NovaMovimentacaoScreenState();
}

class _NovaMovimentacaoScreenState extends ConsumerState<NovaMovimentacaoScreen> {
  final _form = GlobalKey<FormState>();
  final _quantidade = TextEditingController();
  final _preco = TextEditingController();
  final _observacao = TextEditingController();
  late String _tipo;
  FornecedorEstoque? _fornecedor;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial ?? 'Entrada';
  }

  @override
  void dispose() {
    _quantidade.dispose();
    _preco.dispose();
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await ref.read(estoqueDataSourceProvider).registrarMovimentacao(
            produtoId: widget.produto.id,
            fornecedorId: _fornecedor?.id,
            tipo: _tipo,
            quantidade: double.parse(_quantidade.text),
            precoUnitario: _preco.text.isNotEmpty ? double.tryParse(_preco.text) : null,
            observacao: _observacao.text.trim().isNotEmpty ? _observacao.text.trim() : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fornecedoresEstoqueProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Registrar movimentação'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Produto info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            color: AppColors.accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.produto.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(
                                '${widget.produto.codigo} · Estoque atual: ${widget.produto.quantidadeAtual.toStringAsFixed(0)} ${widget.produto.unidade == 'Unidade' ? 'un' : widget.produto.unidade}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.ink2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tipo
                  const Text('TIPO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TipoChip(label: 'Entrada', icon: Icons.add_circle_outline,
                          color: AppColors.ok, selected: _tipo == 'Entrada',
                          onTap: () => setState(() => _tipo = 'Entrada')),
                      const SizedBox(width: 10),
                      _TipoChip(label: 'Saída', icon: Icons.remove_circle_outline,
                          color: AppColors.danger, selected: _tipo == 'Saida',
                          onTap: () => setState(() => _tipo = 'Saida')),
                      const SizedBox(width: 10),
                      _TipoChip(label: 'Ajuste', icon: Icons.tune_outlined,
                          color: AppColors.accent, selected: _tipo == 'Ajuste',
                          onTap: () => setState(() => _tipo = 'Ajuste')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quantidade
                  TextFormField(
                    controller: _quantidade,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      suffixText: widget.produto.unidade == 'Unidade'
                          ? 'un'
                          : widget.produto.unidade,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obrigatório';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Preço unitário (só entrada)
                  if (_tipo == 'Entrada') ...[
                    TextFormField(
                      controller: _preco,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preço unitário (opcional)',
                        prefixText: 'R\$ ',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fornecedor
                    GamaSearchableSelect<FornecedorEstoque>(
                      label: 'Fornecedor (opcional)',
                      selectedValue: _fornecedor,
                      displayString: (f) => f.nome,
                      optionsBuilder: (query) async {
                        final all = ref.read(fornecedoresEstoqueProvider).value ?? [];
                        return all
                            .where((f) => f.nome.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                      },
                      onChanged: (f) => setState(() => _fornecedor = f),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Observação
                  TextFormField(
                    controller: _observacao,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observação (opcional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
            child: FilledButton(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black54),
                    )
                  : const Text('Registrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  const _TipoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(20) : AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.ink3, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? color : AppColors.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}
