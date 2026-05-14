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
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Produto info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 22),
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
                              fontSize: 12, color: AppColors.textSecondary),
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
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Row(
              children: [
                _TipoChip(label: 'Entrada', icon: Icons.add_circle_outline,
                    color: AppColors.success, selected: _tipo == 'Entrada',
                    onTap: () => setState(() => _tipo = 'Entrada')),
                const SizedBox(width: 10),
                _TipoChip(label: 'Saída', icon: Icons.remove_circle_outline,
                    color: AppColors.error, selected: _tipo == 'Saida',
                    onTap: () => setState(() => _tipo = 'Saida')),
                const SizedBox(width: 10),
                _TipoChip(label: 'Ajuste', icon: Icons.tune_outlined,
                    color: AppColors.primary, selected: _tipo == 'Ajuste',
                    onTap: () => setState(() => _tipo = 'Ajuste')),
              ],
            ),
            const SizedBox(height: 20),

            // Quantidade
            TextFormField(
              controller: _quantidade,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDec('Quantidade',
                  suffix: widget.produto.unidade == 'Unidade'
                      ? 'un'
                      : widget.produto.unidade),
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
                decoration: _inputDec('Preço unitário (opcional)', prefix: 'R\$ '),
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
              decoration: _inputDec('Observação (opcional)'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, {String? prefix, String? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );
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
            color: selected ? color.withAlpha(20) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.textSecondary, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? color : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
