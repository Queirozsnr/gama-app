import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/estoque_remote_data_source.dart';
import '../domain/estoque.dart';
import 'estoque_notifier.dart';

class FornecedoresScreen extends ConsumerWidget {
  const FornecedoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fornecedoresEstoqueProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Fornecedores'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Erro ao carregar fornecedores',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (fornecedores) {
          if (fornecedores.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('Nenhum fornecedor cadastrado',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _abrirForm(context, ref, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo fornecedor'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: fornecedores.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, i) => _FornecedorTile(
              fornecedor: fornecedores[i],
              onEdit: () => _abrirForm(context, ref, fornecedores[i]),
              onDelete: () => _confirmarExclusao(context, ref, fornecedores[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirForm(
      BuildContext context, WidgetRef ref, FornecedorEstoque? fornecedor) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FornecedorForm(fornecedor: fornecedor),
    );
    if (ok == true) ref.invalidate(fornecedoresEstoqueProvider);
  }

  Future<void> _confirmarExclusao(
      BuildContext context, WidgetRef ref, FornecedorEstoque fornecedor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir fornecedor'),
        content: Text(
            'Deseja excluir "${fornecedor.nome}"? As movimentações vinculadas não serão afetadas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(estoqueDataSourceProvider).excluirFornecedor(fornecedor.id);
        ref.invalidate(fornecedoresEstoqueProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _FornecedorTile extends StatelessWidget {
  const _FornecedorTile({
    required this.fornecedor,
    required this.onEdit,
    required this.onDelete,
  });

  final FornecedorEstoque fornecedor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.local_shipping_outlined,
            size: 20, color: AppColors.primary),
      ),
      title: Text(fornecedor.nome,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: fornecedor.telefone != null || fornecedor.email != null
          ? Text(
              [fornecedor.telefone, fornecedor.email]
                  .whereType<String>()
                  .join(' · '),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'Excluir',
          ),
        ],
      ),
    );
  }
}

class _FornecedorForm extends ConsumerStatefulWidget {
  const _FornecedorForm({this.fornecedor});
  final FornecedorEstoque? fornecedor;

  @override
  ConsumerState<_FornecedorForm> createState() => _FornecedorFormState();
}

class _FornecedorFormState extends ConsumerState<_FornecedorForm> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  bool _salvando = false;

  bool get _editando => widget.fornecedor != null;

  @override
  void initState() {
    super.initState();
    if (widget.fornecedor != null) {
      _nome.text = widget.fornecedor!.nome;
      _telefone.text = widget.fornecedor!.telefone ?? '';
      _email.text = widget.fornecedor!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final ds = ref.read(estoqueDataSourceProvider);
      final telefone = _telefone.text.trim().isNotEmpty ? _telefone.text.trim() : null;
      final email = _email.text.trim().isNotEmpty ? _email.text.trim() : null;

      if (_editando) {
        await ds.atualizarFornecedor(
          id: widget.fornecedor!.id,
          nome: _nome.text.trim(),
          telefone: telefone,
          email: email,
        );
      } else {
        await ds.criarFornecedor(
          nome: _nome.text.trim(),
          telefone: telefone,
          email: email,
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  _editando ? 'Editar fornecedor' : 'Novo fornecedor',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(_nome, 'Nome *',
                validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null),
            const SizedBox(height: 12),
            _field(_telefone, 'Telefone (opcional)',
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_email, 'E-mail (opcional)',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      );
}
