import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_button.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/oficina_model.dart';
import 'oficinas_notifier.dart';

class GerenciarOficinasScreen extends ConsumerWidget {
  const GerenciarOficinasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(oficinasNotifierProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Erro ao carregar oficinas',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            GamaButton(
              label: 'Tentar novamente',
              isFullWidth: false,
              onPressed: () => ref.invalidate(oficinasNotifierProvider),
            ),
          ],
        ),
      ),
      data: (oficinas) => _Content(
        oficinas: oficinas,
        onAdd: () => _showForm(context, ref, null),
        onEdit: (o) => _showForm(context, ref, o),
        onDelete: (o) => _confirmDelete(context, ref, o),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, OficinaModel? oficina) {
    showDialog(
      context: context,
      builder: (_) => _OficinaFormDialog(oficina: oficina, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, OficinaModel oficina) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir oficina',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Deseja excluir "${oficina.nome}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(oficinasNotifierProvider.notifier).excluir(oficina.id);
                if (context.mounted) GamaSnackBar.success(context, 'Oficina excluída.');
              } catch (e) {
                if (context.mounted) GamaSnackBar.error(context, e.toString());
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.oficinas,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OficinaModel> oficinas;
  final VoidCallback onAdd;
  final void Function(OficinaModel) onEdit;
  final void Function(OficinaModel) onDelete;

  int get _ativas => oficinas.where((o) => o.ativo).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unidades cadastradas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oficinas.isEmpty
                          ? 'Nenhuma unidade cadastrada ainda'
                          : '$_ativas de ${oficinas.length} ${oficinas.length == 1 ? 'unidade ativa' : 'unidades ativas'}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GamaButton(
                label: 'Nova oficina',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: onAdd,
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (oficinas.isEmpty)
            _EmptyState(onAdd: onAdd)
          else
            ...oficinas.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OficinaCard(
                    oficina: o,
                    onEdit: () => onEdit(o),
                    onDelete: () => onDelete(o),
                  ),
                )),
        ],
      ),
    );
  }
}

class _OficinaCard extends StatefulWidget {
  const _OficinaCard({required this.oficina, required this.onEdit, required this.onDelete});
  final OficinaModel oficina;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_OficinaCard> createState() => _OficinaCardState();
}

class _OficinaCardState extends State<_OficinaCard> {
  bool _hovered = false;

  String get _initials {
    final parts = widget.oficina.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return widget.oficina.nome.substring(0, widget.oficina.nome.length.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: _hovered ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            GamaAvatar(initials: _initials, size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.oficina.nome,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(ativo: widget.oficina.ativo),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (widget.oficina.endereco.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.oficina.endereco,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.oficina.telefone.isNotEmpty)
                          const SizedBox(width: 16),
                      ],
                      if (widget.oficina.telefone.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.oficina.telefone,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      if (widget.oficina.endereco.isEmpty && widget.oficina.telefone.isEmpty)
                        const Text(
                          'Sem endereço ou telefone cadastrado',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 150),
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    tooltip: 'Editar',
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    tooltip: 'Excluir',
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.color, required this.tooltip, required this.onTap});
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.ativo});
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: ativo ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ativo ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            ativo ? 'Ativa' : 'Inativa',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ativo ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.store_mall_directory_outlined, size: 34, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma oficina cadastrada',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Adicione a primeira unidade do seu grupo.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          GamaButton(label: 'Adicionar oficina', icon: Icons.add, isFullWidth: false, onPressed: onAdd),
        ],
      ),
    );
  }
}

// ── Form Dialog ────────────────────────────────────────────────────────────────

class _OficinaFormDialog extends StatefulWidget {
  const _OficinaFormDialog({required this.oficina, required this.ref});
  final OficinaModel? oficina;
  final WidgetRef ref;

  @override
  State<_OficinaFormDialog> createState() => _OficinaFormDialogState();
}

class _OficinaFormDialogState extends State<_OficinaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl = TextEditingController(text: widget.oficina?.nome);
  late final _enderecoCtrl = TextEditingController(text: widget.oficina?.endereco);
  late final _telefoneCtrl = TextEditingController(text: widget.oficina?.telefone);
  late bool _ativo = widget.oficina?.ativo ?? true;
  bool _loading = false;

  bool get _isEditing => widget.oficina != null;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _enderecoCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEditing) {
        await widget.ref.read(oficinasNotifierProvider.notifier).atualizar(
              widget.oficina!.id,
              nome: _nomeCtrl.text.trim(),
              endereco: _enderecoCtrl.text.trim(),
              telefone: _telefoneCtrl.text.trim(),
              ativo: _ativo,
              telefone2: widget.oficina!.telefone2,
              email: widget.oficina!.email,
              whatsapp: widget.oficina!.whatsapp,
              instagram: widget.oficina!.instagram,
              cnpj: widget.oficina!.cnpj,
              corPadrao: widget.oficina!.corPadrao,
            );
      } else {
        await widget.ref.read(oficinasNotifierProvider.notifier).criar(
              nome: _nomeCtrl.text.trim(),
              endereco: _enderecoCtrl.text.trim(),
              telefone: _telefoneCtrl.text.trim(),
            );
      }
      if (mounted) {
        Navigator.of(context).pop();
        GamaSnackBar.success(context, _isEditing ? 'Oficina atualizada.' : 'Oficina criada com sucesso.');
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_outlined, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _isEditing ? 'Editar oficina' : 'Nova oficina',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Field(
                label: 'Nome da oficina *',
                controller: _nomeCtrl,
                hint: 'Ex: Centro, Zona Sul, Filial 2...',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Endereço',
                controller: _enderecoCtrl,
                hint: 'Rua, número, bairro, cidade',
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Telefone',
                controller: _telefoneCtrl,
                hint: '(11) 99999-9999',
                keyboardType: TextInputType.phone,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _ativo ? Icons.check_circle_outline : Icons.cancel_outlined,
                        size: 18,
                        color: _ativo ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _ativo ? 'Oficina ativa' : 'Oficina inativa',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      Switch(
                        value: _ativo,
                        onChanged: (v) => setState(() => _ativo = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  GamaButton(
                    label: _isEditing ? 'Salvar alterações' : 'Criar oficina',
                    isLoading: _loading,
                    isFullWidth: false,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, this.hint, this.validator, this.keyboardType});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
