import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/estoque.dart';
import 'fornecedores_notifier.dart';

class FornecedoresScreen extends ConsumerStatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  ConsumerState<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends ConsumerState<FornecedoresScreen>
    with TopBarSlotMixin<FornecedoresScreen> {
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setTopBarSlot(TopBarSlot(
      searchController: _searchController,
      searchHint: 'Buscar por nome, e-mail ou telefone…',
      onSearchChanged: (v) =>
          ref.read(fornecedoresNotifierProvider.notifier).buscar(v),
      action: FilledButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, size: 17),
        label: const Text('Novo fornecedor'),
      ),
      mobileAction: IconButton(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        color: AppColors.accent,
        tooltip: 'Novo fornecedor',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ));
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchController.dispose());
  }

  Future<void> _openForm({FornecedorEstoque? fornecedor}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FornecedorFormDialog(fornecedor: fornecedor),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        fornecedor == null ? 'Fornecedor criado!' : 'Fornecedor atualizado!',
      );
    }
  }

  Future<void> _excluir(FornecedorEstoque f) async {
    final ok = await GamaConfirmDialog.show(
      context,
      title: 'Excluir fornecedor',
      message: 'Deseja excluir "${f.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (ok && mounted) {
      try {
        await ref.read(fornecedoresNotifierProvider.notifier).excluir(f.id);
        if (mounted) GamaSnackBar.success(context, 'Fornecedor removido.');
      } catch (_) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao excluir fornecedor.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(fornecedoresNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text('Erro ao carregar fornecedores',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(fornecedoresNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  const Text('Nenhum fornecedor encontrado',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Toque no + para adicionar o primeiro',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(fornecedoresNotifierProvider.notifier).buscar(
                      _searchController.text.isEmpty
                          ? null
                          : _searchController.text,
                    ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lista.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final f = lista[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    child: Text(
                      f.nome.isNotEmpty ? f.nome[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  title: Text(
                    f.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                  subtitle: f.email != null || f.telefone != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (f.email != null) f.email!,
                              if (f.telefone != null) f.telefone!,
                            ].join(' · '),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.textSecondary),
                        tooltip: 'Editar',
                        onPressed: () => _openForm(fornecedor: f),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.textSecondary),
                        tooltip: 'Excluir',
                        onPressed: () => _excluir(f),
                      ),
                    ],
                  ),
                  onTap: () => _openForm(fornecedor: f),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Form dialog ───────────────────────────────────────────────────────────────

class _FornecedorFormDialog extends ConsumerStatefulWidget {
  const _FornecedorFormDialog({this.fornecedor});
  final FornecedorEstoque? fornecedor;

  @override
  ConsumerState<_FornecedorFormDialog> createState() =>
      _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends ConsumerState<_FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl =
      TextEditingController(text: widget.fornecedor?.nome ?? '');
  late final _telCtrl =
      TextEditingController(text: widget.fornecedor?.telefone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.fornecedor?.email ?? '');
  bool _loading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(fornecedoresNotifierProvider.notifier);
      if (widget.fornecedor == null) {
        await notifier.criar(
          nome: _nomeCtrl.text.trim(),
          telefone:
              _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          email:
              _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        );
      } else {
        await notifier.atualizar(
          id: widget.fornecedor!.id,
          nome: _nomeCtrl.text.trim(),
          telefone:
              _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          email:
              _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.fornecedor != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar fornecedor' : 'Novo fornecedor'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
