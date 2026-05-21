import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/admin_remote_data_source.dart';
import '../domain/admin_models.dart';
import 'admin_notifier.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final gruposAsync = ref.watch(gruposAdminProvider);

    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GruposSection(gruposAsync: gruposAsync),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 340,
              child: _RegisterForm(onSuccess: () => ref.invalidate(gruposAdminProvider)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _RegisterForm(onSuccess: () => ref.invalidate(gruposAdminProvider)),
          const SizedBox(height: 20),
          _GruposSection(gruposAsync: gruposAsync),
        ],
      ),
    );
  }
}

// ── Grupos ────────────────────────────────────────────────────────────────────

class _GruposSection extends ConsumerWidget {
  const _GruposSection({required this.gruposAsync});
  final AsyncValue<List<GrupoAdminItem>> gruposAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return gruposAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (grupos) => isDesktop
          ? _DesktopGruposTable(
              grupos: grupos,
              onUpdated: () => ref.invalidate(gruposAdminProvider),
            )
          : _MobileGruposList(
              grupos: grupos,
              onUpdated: () => ref.invalidate(gruposAdminProvider),
            ),
    );
  }
}

class _DesktopGruposTable extends StatelessWidget {
  const _DesktopGruposTable({required this.grupos, required this.onUpdated});
  final List<GrupoAdminItem> grupos;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Grupos cadastrados',
      subtitle: '${grupos.length} grupo${grupos.length != 1 ? 's' : ''}',
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 400),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2),
              2: FixedColumnWidth(100),
              3: FixedColumnWidth(110),
              4: FixedColumnWidth(70),
              5: FixedColumnWidth(60),
              6: FixedColumnWidth(80),
            },
            children: [
              _tableHeader(),
              for (final g in grupos) _tableRow(context, g),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _tableHeader() {
    const style = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.ink3,
      letterSpacing: 0.5,
    );
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      children: [
        _th('NOME', style),
        _th('EMAIL', style),
        _th('PLANO', style),
        _th('EXPIRA EM', style),
        _th('OFIC.', style),
        _th('USU.', style),
        _th('', style),
      ],
    );
  }

  Widget _th(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(text, style: style),
      );

  TableRow _tableRow(BuildContext context, GrupoAdminItem g) {
    final expiraLabel = '${g.planoExpiraEm.day.toString().padLeft(2, '0')}/'
        '${g.planoExpiraEm.month.toString().padLeft(2, '0')}/'
        '${g.planoExpiraEm.year}';
    final expirado = g.planoExpiraEm.isBefore(DateTime.now());

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      children: [
        _td(child: Text(g.nome,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
            overflow: TextOverflow.ellipsis)),
        _td(child: Text(g.email,
            style: const TextStyle(fontSize: 12, color: AppColors.ink2),
            overflow: TextOverflow.ellipsis)),
        _td(child: _PlanoChip(plano: g.plano)),
        _td(child: Text(expiraLabel,
            style: TextStyle(
              fontSize: 12,
              color: expirado ? AppColors.danger : AppColors.ink2,
              fontFamily: 'JetBrains Mono',
            ))),
        _td(child: Text('${g.totalOficinas}',
            style: const TextStyle(fontSize: 13, color: AppColors.ink))),
        _td(child: Text('${g.totalUsuarios}',
            style: const TextStyle(fontSize: 13, color: AppColors.ink))),
        _td(
          child: TextButton(
            onPressed: () => _showEditPlano(context, g),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Editar', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _td({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      );

  void _showEditPlano(BuildContext context, GrupoAdminItem g) {
    showDialog(
      context: context,
      builder: (_) => _EditClienteDialog(grupo: g, onUpdated: onUpdated),
    );
  }
}

class _MobileGruposList extends StatelessWidget {
  const _MobileGruposList({required this.grupos, required this.onUpdated});
  final List<GrupoAdminItem> grupos;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Grupos cadastrados',
      subtitle: '${grupos.length} grupo${grupos.length != 1 ? 's' : ''}',
      padding: EdgeInsets.zero,
      child: Column(
        children: grupos.map((g) {
          final expirado = g.planoExpiraEm.isBefore(DateTime.now());
          final expiraLabel = '${g.planoExpiraEm.day.toString().padLeft(2, '0')}/'
              '${g.planoExpiraEm.month.toString().padLeft(2, '0')}/'
              '${g.planoExpiraEm.year}';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.nome,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(g.email,
                              style: const TextStyle(fontSize: 12, color: AppColors.ink2)),
                          const SizedBox(height: 6),
                          Row(children: [
                            _PlanoChip(plano: g.plano),
                            const SizedBox(width: 8),
                            Text(expiraLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: expirado ? AppColors.danger : AppColors.ink3,
                                  fontFamily: 'JetBrains Mono',
                                )),
                          ]),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _EditClienteDialog(grupo: g, onUpdated: onUpdated),
                      ),
                      child: const Text('Editar plano'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Edit cliente dialog ───────────────────────────────────────────────────────

class _EditClienteDialog extends ConsumerStatefulWidget {
  const _EditClienteDialog({required this.grupo, required this.onUpdated});
  final GrupoAdminItem grupo;
  final VoidCallback onUpdated;

  @override
  ConsumerState<_EditClienteDialog> createState() => _EditClienteDialogState();
}

class _EditClienteDialogState extends ConsumerState<_EditClienteDialog> {
  static const _planos = ['Trial', 'Basico', 'Pro', 'Enterprise'];

  late String _plano;
  late DateTime _expiraEm;
  late final TextEditingController _nome;
  late final TextEditingController _email;
  final TextEditingController _senha = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _plano = widget.grupo.plano;
    _expiraEm = widget.grupo.planoExpiraEm;
    _nome = TextEditingController(text: widget.grupo.nomeUsuario ?? '');
    _email = TextEditingController(text: widget.grupo.email);
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final userId = widget.grupo.userId;
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(adminRemoteDataSourceProvider).atualizarCliente(
            grupoId: widget.grupo.id,
            plano: _plano,
            expiraEm: _expiraEm,
            userId: userId,
            nomeUsuario: _nome.text.trim(),
            email: _email.text.trim(),
            novaSenha: _senha.text.isNotEmpty ? _senha.text : null,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        GamaSnackBar.success(context, 'Cliente atualizado.');
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiraEm,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiraEm = picked);
  }

  @override
  Widget build(BuildContext context) {
    final expiraLabel = '${_expiraEm.day.toString().padLeft(2, '0')}/'
        '${_expiraEm.month.toString().padLeft(2, '0')}/'
        '${_expiraEm.year}';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.grupo.nome,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DialogLabel('Responsável'),
              const SizedBox(height: 6),
              TextField(
                controller: _nome,
                decoration: InputDecoration(
                  hintText: 'Nome completo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const _DialogLabel('E-mail'),
              const SizedBox(height: 6),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'email@exemplo.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const _DialogLabel('Nova senha (deixe em branco para manter)'),
              const SizedBox(height: 6),
              TextField(
                controller: _senha,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mínimo 8 caracteres',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18, color: AppColors.ink3,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const _DialogLabel('Plano'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _plano,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: _planos
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _plano = v!),
                ),
              ),
              const SizedBox(height: 12),
              const _DialogLabel('Expira em'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.ink3),
                      const SizedBox(width: 8),
                      Text(expiraLabel,
                          style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2)),
        ),
        FilledButton(
          onPressed: _loading ? null : _salvar,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Salvar', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink3),
      );
}

// ── Register form ─────────────────────────────────────────────────────────────

class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm({required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeGrupo = TextEditingController();
  final _nomeUsuario = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nomeGrupo.dispose();
    _nomeUsuario.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(adminRemoteDataSourceProvider).registrar(
            nomeGrupo: _nomeGrupo.text.trim(),
            nomeUsuario: _nomeUsuario.text.trim(),
            email: _email.text.trim(),
            senha: _senha.text,
          );
      if (mounted) {
        _formKey.currentState?.reset();
        _nomeGrupo.clear();
        _nomeUsuario.clear();
        _email.clear();
        _senha.clear();
        widget.onSuccess();
        GamaSnackBar.success(context, 'Cliente registrado com sucesso.');
      }
    } catch (e) {
      if (mounted) GamaSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Registrar cliente',
      subtitle: 'Cria grupo, usuário e oficina principal',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _Field(
              controller: _nomeGrupo,
              label: 'Nome da oficina / grupo',
              hint: 'Ex: Auto Center Silva',
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _nomeUsuario,
              label: 'Nome do responsável',
              hint: 'Ex: João Silva',
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _email,
              label: 'E-mail',
              hint: 'joao@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Obrigatório';
                if (!v!.contains('@')) return 'E-mail inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Mínimo 8 caracteres',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18, color: AppColors.ink3),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Obrigatório';
                if (v!.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                    : const Text('Criar cliente',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: validator,
    );
  }
}

// ── Plano chip ────────────────────────────────────────────────────────────────

class _PlanoChip extends StatelessWidget {
  const _PlanoChip({required this.plano});
  final String plano;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (plano) {
      'Trial'      => (AppColors.ink.withValues(alpha: 0.08), AppColors.ink2),
      'Basico'     => (const Color(0xFF3B82F6).withValues(alpha: 0.12), const Color(0xFF2563EB)),
      'Pro'        => (AppColors.accentSoft, AppColors.accent),
      'Enterprise' => (const Color(0xFF8B5CF6).withValues(alpha: 0.12), const Color(0xFF7C3AED)),
      _            => (AppColors.line, AppColors.ink3),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        plano.toUpperCase(),
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
