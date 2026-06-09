import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/admin_remote_data_source.dart';
import '../domain/admin_models.dart';
import '../../../features/assinatura/presentation/assinatura_notifier.dart';
import 'admin_notifier.dart';

// ── Status derivado ───────────────────────────────────────────────────────────

enum _GrupoStatus { trial, ativo, cancelando, expirado, bloqueado }

extension _GrupoAdminItemX on GrupoAdminItem {
  _GrupoStatus get status {
    if (!ativo) return _GrupoStatus.bloqueado;
    if (planoExpiraEm.isBefore(DateTime.now())) return _GrupoStatus.expirado;
    if (cancelamentoAgendado) return _GrupoStatus.cancelando;
    if (plano == 'Trial') return _GrupoStatus.trial;
    return _GrupoStatus.ativo;
  }

  bool get trialAcabando =>
      plano == 'Trial' &&
      planoExpiraEm.isAfter(DateTime.now()) &&
      planoExpiraEm.isBefore(DateTime.now().add(const Duration(days: 7)));
}

// ── Filtro ────────────────────────────────────────────────────────────────────

enum _Filtro { todos, trial, ativo, expirado }

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final gruposAsync = ref.watch(gruposAdminProvider);
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final nome = oficinas.cast<OficinaItem?>().firstWhere(
          (o) => o!.id == auth?.oficinaId,
          orElse: () => null,
        )?.nome;

    final content = isDesktop
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _KpiSection(gruposAsync: gruposAsync),
                      const SizedBox(height: 20),
                      _GruposSection(gruposAsync: gruposAsync),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 340,
                  child: Column(
                    children: [
                      _RegisterForm(onSuccess: () => ref.invalidate(gruposAdminProvider)),
                      const SizedBox(height: 20),
                      _TrialsAcabandoPanel(gruposAsync: gruposAsync),
                    ],
                  ),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _KpiSection(gruposAsync: gruposAsync),
                const SizedBox(height: 16),
                _RegisterForm(onSuccess: () => ref.invalidate(gruposAdminProvider)),
                const SizedBox(height: 16),
                _GruposSection(gruposAsync: gruposAsync),
              ],
            ),
          );

    return TopBarSlotProvider(
      slot: TopBarSlot(
        pageTitle: 'Admin',
        mobileStyle: MobileTopBarStyle.dark,
        mobileSubtitle: nome != null ? '• $nome' : null,
      ),
      child: content,
    );
  }
}

// ── KPI cards ─────────────────────────────────────────────────────────────────

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.gruposAsync});
  final AsyncValue<List<GrupoAdminItem>> gruposAsync;

  @override
  Widget build(BuildContext context) {
    return gruposAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (grupos) {
        final total = grupos.length;
        final trials = grupos.where((g) => g.status == _GrupoStatus.trial).length;
        final ativos = grupos.where((g) => g.status == _GrupoStatus.ativo).length;
        final expirados = grupos.where((g) => g.status == _GrupoStatus.expirado).length;

        return Row(
          children: [
            Expanded(child: _KpiCard(label: 'Total', value: '$total')),
            const SizedBox(width: 12),
            Expanded(
                child: _KpiCard(
                    label: 'Trials ativos',
                    value: '$trials',
                    color: AppColors.accentDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _KpiCard(
                    label: 'Pagos ativos',
                    value: '$ativos',
                    color: const Color(0xFF22C55E))),
            const SizedBox(width: 12),
            Expanded(
                child: _KpiCard(
                    label: 'Expirados',
                    value: '$expirados',
                    color: expirados > 0 ? AppColors.danger : AppColors.ink3)),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.ink,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

// ── Trials acabando ───────────────────────────────────────────────────────────

class _TrialsAcabandoPanel extends StatelessWidget {
  const _TrialsAcabandoPanel({required this.gruposAsync});
  final AsyncValue<List<GrupoAdminItem>> gruposAsync;

  @override
  Widget build(BuildContext context) {
    return gruposAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (grupos) {
        final acabando = grupos
            .where((g) => g.trialAcabando)
            .toList()
          ..sort((a, b) => a.planoExpiraEm.compareTo(b.planoExpiraEm));
        if (acabando.isEmpty) return const SizedBox.shrink();

        return SectionCard(
            title: 'Trials acabando',
            subtitle: 'Próximos 7 dias',
            padding: EdgeInsets.zero,
            child: Column(
              children: acabando.map((g) {
                final dias = g.planoExpiraEm.difference(DateTime.now()).inDays + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accentSoft,
                        child: Text(
                          g.nome.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentDark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(g.nome,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: dias <= 2
                              ? AppColors.danger.withValues(alpha: 0.1)
                              : AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${dias}d',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'JetBrains Mono',
                            color: dias <= 2 ? AppColors.danger : AppColors.accentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
      },
    );
  }
}

// ── Grupos section com filtro ─────────────────────────────────────────────────

class _GruposSection extends ConsumerStatefulWidget {
  const _GruposSection({required this.gruposAsync});
  final AsyncValue<List<GrupoAdminItem>> gruposAsync;

  @override
  ConsumerState<_GruposSection> createState() => _GruposSectionState();
}

class _GruposSectionState extends ConsumerState<_GruposSection> {
  _Filtro _filtro = _Filtro.todos;

  List<GrupoAdminItem> _filtrar(List<GrupoAdminItem> todos) => switch (_filtro) {
        _Filtro.todos => todos,
        _Filtro.trial => todos.where((g) => g.status == _GrupoStatus.trial).toList(),
        _Filtro.ativo => todos.where((g) => g.status == _GrupoStatus.ativo).toList(),
        _Filtro.expirado =>
          todos.where((g) => g.status == _GrupoStatus.expirado).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return widget.gruposAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (todos) {
        final grupos = _filtrar(todos);

        return SectionCard(
          title: 'Grupos cadastrados',
          subtitle:
              '${grupos.length} de ${todos.length} grupo${todos.length != 1 ? 's' : ''}',
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterTabs(
                filtro: _filtro,
                todos: todos,
                onChanged: (f) => setState(() => _filtro = f),
              ),
              if (isDesktop)
                _DesktopGruposTable(
                  grupos: grupos,
                  onUpdated: () => ref.invalidate(gruposAdminProvider),
                )
              else
                _MobileGruposList(
                  grupos: grupos,
                  onUpdated: () => ref.invalidate(gruposAdminProvider),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.filtro,
    required this.todos,
    required this.onChanged,
  });

  final _Filtro filtro;
  final List<GrupoAdminItem> todos;
  final void Function(_Filtro) onChanged;

  @override
  Widget build(BuildContext context) {
    int count(_Filtro f) => switch (f) {
          _Filtro.todos => todos.length,
          _Filtro.trial =>
            todos.where((g) => g.status == _GrupoStatus.trial).length,
          _Filtro.ativo =>
            todos.where((g) => g.status == _GrupoStatus.ativo).length,
          _Filtro.expirado =>
            todos.where((g) => g.status == _GrupoStatus.expirado).length,
        };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 6,
        children: _Filtro.values.map((f) {
          final active = f == filtro;
          final label = switch (f) {
            _Filtro.todos => 'Todos',
            _Filtro.trial => 'Trial',
            _Filtro.ativo => 'Ativos',
            _Filtro.expirado => 'Expirados',
          };
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.line,
                ),
              ),
              child: Text(
                '$label · ${count(f)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.ink : AppColors.ink3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Desktop table ─────────────────────────────────────────────────────────────

class _DesktopGruposTable extends StatelessWidget {
  const _DesktopGruposTable({required this.grupos, required this.onUpdated});
  final List<GrupoAdminItem> grupos;
  final VoidCallback onUpdated;

  static const _kColPlano  = 100.0;
  static const _kColStatus = 90.0;
  static const _kColExpira = 100.0;
  static const _kColOfic   = 44.0;
  static const _kColUsu    = 44.0;
  static const _kColAcoes  = 64.0;
  static const _kPadH      = 16.0;

  @override
  Widget build(BuildContext context) {
    if (grupos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Nenhum grupo neste filtro.',
              style: TextStyle(fontSize: 13, color: AppColors.ink3)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const Divider(height: 1),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: grupos.length,
          itemBuilder: (ctx, i) => _row(ctx, grupos[i], i == grupos.length - 1),
        ),
      ],
    );
  }

  Widget _header() => Container(
        height: 38,
        color: AppColors.surface2,
        padding: const EdgeInsets.symmetric(horizontal: _kPadH),
        child: const Row(children: [
          Expanded(flex: 3, child: _ColLabel('NOME')),
          SizedBox(width: 12),
          Expanded(flex: 2, child: _ColLabel('EMAIL')),
          SizedBox(width: 12),
          SizedBox(width: _kColPlano, child: _ColLabel('PLANO')),
          SizedBox(width: 8),
          SizedBox(width: _kColStatus, child: _ColLabel('STATUS')),
          SizedBox(width: 8),
          SizedBox(width: _kColExpira, child: _ColLabel('EXPIRA EM')),
          SizedBox(width: 8),
          SizedBox(width: _kColOfic, child: _ColLabel('OFIC.')),
          SizedBox(width: 8),
          SizedBox(width: _kColUsu, child: _ColLabel('USU.')),
          SizedBox(width: _kColAcoes),
        ]),
      );

  Widget _row(BuildContext context, GrupoAdminItem g, bool isLast) {
    final expiraLabel = '${g.planoExpiraEm.day.toString().padLeft(2, '0')}/'
        '${g.planoExpiraEm.month.toString().padLeft(2, '0')}/'
        '${g.planoExpiraEm.year}';
    final expirado = g.planoExpiraEm.isBefore(DateTime.now());

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kPadH),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(g.nome,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(g.email,
              style: const TextStyle(fontSize: 12, color: AppColors.ink2),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 12),
        SizedBox(width: _kColPlano, child: _PlanoChip(plano: g.plano)),
        const SizedBox(width: 8),
        SizedBox(width: _kColStatus, child: _StatusChip(status: g.status)),
        const SizedBox(width: 8),
        SizedBox(
          width: _kColExpira,
          child: Text(expiraLabel,
              style: TextStyle(
                fontSize: 12,
                color: expirado ? AppColors.danger : AppColors.ink2,
                fontFamily: 'JetBrains Mono',
              )),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _kColOfic,
          child: Text('${g.totalOficinas}',
              style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _kColUsu,
          child: Text('${g.totalUsuarios}',
              style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        ),
        SizedBox(
          width: _kColAcoes,
          child: TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _EditClienteDialog(grupo: g, onUpdated: onUpdated),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Editar', style: TextStyle(fontSize: 12)),
          ),
        ),
      ]),
    );
  }
}

class _ColLabel extends StatelessWidget {
  const _ColLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.ink3,
          letterSpacing: 0.5,
        ),
      );
}

// ── Mobile list ───────────────────────────────────────────────────────────────

class _MobileGruposList extends StatelessWidget {
  const _MobileGruposList({required this.grupos, required this.onUpdated});
  final List<GrupoAdminItem> grupos;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    if (grupos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('Nenhum grupo neste filtro.',
              style: TextStyle(fontSize: 13, color: AppColors.ink3)),
        ),
      );
    }

    return Column(
      children: grupos.map((g) {
        final expirado = g.planoExpiraEm.isBefore(DateTime.now());
        final expiraLabel =
            '${g.planoExpiraEm.day.toString().padLeft(2, '0')}/'
            '${g.planoExpiraEm.month.toString().padLeft(2, '0')}/'
            '${g.planoExpiraEm.year}';
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.nome,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(g.email,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.ink2)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _PlanoChip(plano: g.plano),
                          const SizedBox(width: 6),
                          _StatusChip(status: g.status),
                          const SizedBox(width: 8),
                          Text(expiraLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: expirado
                                    ? AppColors.danger
                                    : AppColors.ink3,
                                fontFamily: 'JetBrains Mono',
                              )),
                        ]),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                          _EditClienteDialog(grupo: g, onUpdated: onUpdated),
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
    );
  }
}

// ── Edit dialog ───────────────────────────────────────────────────────────────

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
  late String _ciclo;
  late DateTime _expiraEm;
  late bool _bloqueado;
  late final TextEditingController _nome;
  late final TextEditingController _email;
  final TextEditingController _senha = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _plano = widget.grupo.plano;
    _ciclo = widget.grupo.ciclo;
    _expiraEm = widget.grupo.planoExpiraEm;
    _bloqueado = !widget.grupo.ativo;
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
            ciclo: _ciclo,
            expiraEm: _expiraEm,
            userId: userId,
            nomeUsuario: _nome.text.trim(),
            email: _email.text.trim(),
            novaSenha: _senha.text.isNotEmpty ? _senha.text : null,
            bloqueado: _bloqueado != !widget.grupo.ativo ? _bloqueado : null,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ref.invalidate(assinaturaProvider);
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
      initialDate: _expiraEm.isBefore(DateTime.now()) ? DateTime.now() : _expiraEm,
      firstDate: DateTime(2020), // admins podem ver/corrigir datas passadas
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiraEm = picked);
  }

  @override
  Widget build(BuildContext context) {
    final expiraLabel = '${_expiraEm.day.toString().padLeft(2, '0')}/'
        '${_expiraEm.month.toString().padLeft(2, '0')}/'
        '${_expiraEm.year}';
    final expirado = _expiraEm.isBefore(DateTime.now());

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.grupo.nome,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink)),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              const _DialogLabel(
                  'Nova senha (deixe em branco para manter)'),
              const SizedBox(height: 6),
              TextField(
                controller: _senha,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mínimo 8 caracteres',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.ink3,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const _DialogLabel('Plano'),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _plano,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: _planos
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _plano = v!),
                ),
              ),
              const SizedBox(height: 12),
              const _DialogLabel('Ciclo de cobrança'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _ciclo,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
                    DropdownMenuItem(value: 'anual', child: Text('Anual')),
                  ],
                  onChanged: (v) => setState(() => _ciclo = v!),
                ),
              ),
              const SizedBox(height: 12),
              const _DialogLabel('Expira em'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: expirado
                            ? AppColors.danger
                            : AppColors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16,
                          color: expirado
                              ? AppColors.danger
                              : AppColors.ink3),
                      const SizedBox(width: 8),
                      Text(expiraLabel,
                          style: TextStyle(
                              fontSize: 14,
                              color: expirado
                                  ? AppColors.danger
                                  : AppColors.ink)),
                      if (expirado) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('expirado',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bloquear acesso',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          _bloqueado
                              ? 'Login e API bloqueados'
                              : 'Conta ativa normalmente',
                          style: TextStyle(
                            fontSize: 11,
                            color: _bloqueado ? AppColors.danger : AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _bloqueado,
                    onChanged: (v) => setState(() => _bloqueado = v),
                    activeThumbColor: AppColors.danger,
                    activeTrackColor: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.ink2)),
        ),
        FilledButton(
          onPressed: _loading ? null : _salvar,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Salvar',
                  style: TextStyle(color: Colors.black87)),
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
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3),
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
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _nomeUsuario,
              label: 'Nome do responsável',
              hint: 'Ex: João Silva',
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Obrigatório' : null,
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.ink3),
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87))
                    : const Text('Criar cliente',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
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
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      'Trial' => (AppColors.ink.withValues(alpha: 0.08), AppColors.ink2),
      'Basico' => (
          const Color(0xFF3B82F6).withValues(alpha: 0.12),
          const Color(0xFF2563EB)
        ),
      'Pro' => (AppColors.accentSoft, AppColors.accentDark),
      'Enterprise' => (
          const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          const Color(0xFF7C3AED)
        ),
      _ => (AppColors.line, AppColors.ink3),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
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

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _GrupoStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _GrupoStatus.trial => (
          'TRIAL',
          AppColors.accentSoft,
          AppColors.accentDark
        ),
      _GrupoStatus.ativo => (
          'ATIVO',
          const Color(0xFF22C55E).withValues(alpha: 0.12),
          const Color(0xFF16A34A)
        ),
      _GrupoStatus.cancelando => (
          'CANCELA',
          AppColors.warn.withValues(alpha: 0.12),
          AppColors.warn
        ),
      _GrupoStatus.expirado => (
          'EXPIRADO',
          AppColors.danger.withValues(alpha: 0.1),
          AppColors.danger
        ),
      _GrupoStatus.bloqueado => (
          'BLOQUEADO',
          AppColors.danger.withValues(alpha: 0.15),
          AppColors.danger
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
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
