import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_searchable_select.dart';
import '../data/estoque_remote_data_source.dart';
import '../domain/estoque.dart';
import 'estoque_notifier.dart';

const _categorias = [
  ('Freios', 'Freios'), ('Filtros', 'Filtros'), ('Lubrificantes', 'Lubrificantes'),
  ('Ignicao', 'Ignição'), ('Motor', 'Motor'), ('Suspensao', 'Suspensão'),
  ('Eletrica', 'Elétrica'), ('Outros', 'Outros'),
];

const _unidades = [
  ('Unidade', 'Unidade (un)'), ('Par', 'Par'), ('Litro', 'Litro (L)'),
  ('Mililitro', 'Mililitro (ml)'), ('Quilograma', 'Quilograma (kg)'),
  ('Metro', 'Metro (m)'), ('Caixa', 'Caixa (cx)'),
];

class NovoProdutoScreen extends ConsumerStatefulWidget {
  const NovoProdutoScreen({super.key, this.produto});
  final ProdutoListagem? produto;

  @override
  ConsumerState<NovoProdutoScreen> createState() => _NovoProdutoScreenState();
}

class _NovoProdutoScreenState extends ConsumerState<NovoProdutoScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _codigo = TextEditingController();
  final _qtdInicial = TextEditingController();
  final _qtdMinima = TextEditingController();
  final _precoCusto = TextEditingController();
  final _precoVenda = TextEditingController();
  String _categoria = 'Freios';
  String _unidade = 'Unidade';
  FornecedorEstoque? _fornecedor;
  bool _salvando = false;

  bool get _editando => widget.produto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    if (p != null) {
      _nome.text = p.nome;
      _codigo.text = p.codigo;
      _qtdMinima.text = p.quantidadeMinima.toStringAsFixed(0);
      _precoVenda.text = p.precoVenda.toStringAsFixed(2);
      _categoria = p.categoria;
      _unidade = p.unidade;
    }
  }

  @override
  void dispose() {
    _nome.dispose(); _codigo.dispose(); _qtdInicial.dispose();
    _qtdMinima.dispose(); _precoCusto.dispose(); _precoVenda.dispose();
    super.dispose();
  }

  double _parse(String v) => double.parse(v.replaceAll(',', '.'));
  double? _tryParse(String v) =>
      v.trim().isEmpty ? null : double.tryParse(v.replaceAll(',', '.'));

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final ds = ref.read(estoqueDataSourceProvider);
      if (_editando) {
        await ds.atualizarProduto(
          id: widget.produto!.id,
          nome: _nome.text.trim(),
          codigo: _codigo.text.trim(),
          categoria: _categoria,
          unidade: _unidade,
          quantidadeMinima: _parse(_qtdMinima.text),
          precoCusto: _tryParse(_precoCusto.text) ?? 0,
          precoVenda: _parse(_precoVenda.text),
        );
      } else {
        await ds.criarProduto(
          nome: _nome.text.trim(),
          codigo: _codigo.text.trim(),
          categoria: _categoria,
          unidade: _unidade,
          quantidadeInicial: _tryParse(_qtdInicial.text) ?? 0,
          quantidadeMinima: _parse(_qtdMinima.text),
          precoCusto: _tryParse(_precoCusto.text) ?? 0,
          precoVenda: _parse(_precoVenda.text),
          fornecedorId: _fornecedor?.id,
        );
      }
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
    if (!_editando) ref.watch(fornecedoresEstoqueProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(_editando ? 'Editar produto' : 'Novo produto'),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(width: 18, height: 18,
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
            _Section('Identificação'),
            _Field(controller: _nome, label: 'Nome do produto',
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            _Field(controller: _codigo, label: 'Código (ex: PF-1042)',
                hint: 'Será convertido para maiúsculas',
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 20),
            _Section('Classificação'),
            GamaSearchableSelect<(String, String)>(
              label: 'Categoria',
              isRequired: true,
              selectedValue: _categorias.where((c) => c.$1 == _categoria).firstOrNull,
              displayString: (c) => c.$2,
              optionsBuilder: (query) async => _categorias
                  .where((c) => c.$2.toLowerCase().contains(query.toLowerCase()))
                  .toList(),
              onChanged: (c) { if (c != null) setState(() => _categoria = c.$1); },
            ),
            const SizedBox(height: 12),
            GamaSearchableSelect<(String, String)>(
              label: 'Unidade de medida',
              isRequired: true,
              selectedValue: _unidades.where((u) => u.$1 == _unidade).firstOrNull,
              displayString: (u) => u.$2,
              optionsBuilder: (query) async => _unidades
                  .where((u) => u.$2.toLowerCase().contains(query.toLowerCase()))
                  .toList(),
              onChanged: (u) { if (u != null) setState(() => _unidade = u.$1); },
            ),
            const SizedBox(height: 20),
            _Section('Estoque'),
            Row(
              children: [
                if (!_editando) ...[
                  Expanded(
                    child: _Field(
                      controller: _qtdInicial, label: 'Qtd. inicial',
                      keyboardType: TextInputType.number,
                      hint: '0',
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _Field(
                    controller: _qtdMinima, label: 'Qtd. mínima',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            if (!_editando) ...[
              const SizedBox(height: 12),
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
            ],
            const SizedBox(height: 20),
            _Section('Preços'),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _precoCusto, label: 'Preço de custo',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: 'R\$ ',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _precoVenda, label: 'Preço de venda',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: 'R\$ ',
                    validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.8)),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.prefix,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
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
        ),
      );
}

