import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../../../shared/widgets/chips/payment_badge.dart';
import '../domain/funcionario.dart';
import 'funcionario_detalhe_notifier.dart';
import 'funcionarios_notifier.dart';
import 'widgets/funcionario_form_dialog.dart';

const _cargoLabels = {
  'Gerente': 'Gerente',
  'Mecanico': 'Mecânico',
  'Auxiliar': 'Auxiliar',
  'Atendente': 'Atendente',
  'Lavador': 'Lavador',
  'Funileiro': 'Funileiro',
  'Eletricista': 'Eletricista',
  'Pintor': 'Pintor',
  'TecnicoArCondicionado': 'Técnico AC',
};

class FuncionarioDetalheScreen extends ConsumerStatefulWidget {
  const FuncionarioDetalheScreen({super.key, required this.funcionarioId});
  final int funcionarioId;

  @override
  ConsumerState<FuncionarioDetalheScreen> createState() =>
      _FuncionarioDetalheScreenState();
}

class _FuncionarioDetalheScreenState
    extends ConsumerState<FuncionarioDetalheScreen>
    with TopBarSlotMixin<FuncionarioDetalheScreen> {
  bool _mobileMenuOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot([Funcionario? f]) {
    final cargoLabel = f == null ? '' : (_cargoLabels[f.cargo] ?? f.cargo);
    setTopBarSlot(TopBarSlot(
      pageTitle: f?.nome ?? 'Ficha do funcionário',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: f == null ? 'FUNCIONÁRIO' : 'EQUIPE · ${cargoLabel.toUpperCase()}',
      mobileAction: f == null
          ? null
          : IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: () => _showMobileMenu(f),
            ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.funcionarios),
        tooltip: 'Voltar',
      ),
      action: f == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editar(f),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _resetarSenha(f),
                  icon: const Icon(Icons.lock_reset_outlined, size: 16),
                  label: const Text('Resetar senha'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
    ));
  }

  void _showMobileMenu(Funcionario f) {
    if (_mobileMenuOpen) return;
    _mobileMenuOpen = true;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar funcionário'),
              onTap: () { Navigator.pop(sheetCtx); _editar(f); },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Resetar senha'),
              onTap: () { Navigator.pop(sheetCtx); _resetarSenha(f); },
            ),
          ],
        ),
      ),
    ).whenComplete(() => _mobileMenuOpen = false);
  }

  Future<void> _editar(Funcionario f) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => FuncionarioFormDialog(funcionario: f),
    );
    if (result == true && mounted) {
      ref.invalidate(funcionarioDetalheProvider(widget.funcionarioId));
      ref.invalidate(funcionariosNotifierProvider);
      GamaSnackBar.success(context, 'Funcionário atualizado!');
    }
  }

  Future<void> _resetarSenha(Funcionario f) async {
    final confirmar = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => GamaConfirmDialog(
            title: 'Resetar senha',
            message: Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Resetar a senha de '),
                  TextSpan(
                    text: f.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: ' para '),
                  const TextSpan(
                    text: 'gama123',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            confirmLabel: 'Resetar',
          ),
        ) ==
        true;
    if (!confirmar || !mounted) return;
    try {
      await ref
          .read(funcionariosNotifierProvider.notifier)
          .resetarSenha(f.id);
      if (mounted) GamaSnackBar.success(context, 'Senha resetada para "gama123".');
    } catch (_) {
      if (mounted) GamaSnackBar.error(context, 'Erro ao resetar senha.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final detalheAsync =
        ref.watch(funcionarioDetalheProvider(widget.funcionarioId));

    return detalheAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        onRetry: () =>
            ref.invalidate(funcionarioDetalheProvider(widget.funcionarioId)),
      ),
      data: (f) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncSlot(f);
        });
        final isDesktop = MediaQuery.of(context).size.width >= 800;
        if (isDesktop) {
          return _DesktopLayout(funcionario: f, onEditar: () => _editar(f));
        }
        return _MobileLayout(
          funcionario: f,
          onEditar: () => _editar(f),
          onResetarSenha: () => _resetarSenha(f),
        );
      },
    );
  }
}

// ── Desktop layout ─────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.funcionario, required this.onEditar});
  final Funcionario funcionario;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(funcionario: funcionario),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _DadosPessoaisCard(
                          funcionario: funcionario, onEditar: onEditar),
                      const SizedBox(height: 14),
                      _OficinasCard(oficinas: funcionario.oficinas),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 288,
                  child: _RemuneracaoCard(funcionario: funcionario),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Profile header strip ───────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.funcionario});
  final Funcionario funcionario;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return funcionario.nome
        .substring(0, funcionario.nome.length.clamp(0, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cargoLabel =
        _cargoLabels[funcionario.cargo] ?? funcionario.cargo;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GamaAvatar(initials: _initials, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      funcionario.nome,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CargoChip(cargo: funcionario.cargo, label: cargoLabel),
                    const SizedBox(width: 6),
                    _AtivoChip(ativo: funcionario.ativo),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _InfoTag(Icons.email_outlined, funcionario.email),
                    if (funcionario.telefone != null) ...[
                      const SizedBox(width: 16),
                      _InfoTag(Icons.phone_outlined, funcionario.telefone!),
                    ],
                    const SizedBox(width: 16),
                    _InfoTag(
                      Icons.calendar_today_outlined,
                      'na GAMA desde ${_fmtDate(funcionario.criadoEm)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.ink3),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
        ),
      ],
    );
  }
}

class _CargoChip extends StatelessWidget {
  const _CargoChip({required this.cargo, required this.label});
  final String cargo;
  final String label;

  Color get _bg => switch (cargo) {
        'Gerente' => AppColors.warnSoft,
        'Mecanico' || 'Auxiliar' || 'Funileiro' => AppColors.infoSoft,
        _ => AppColors.bg,
      };

  Color get _fg => switch (cargo) {
        'Gerente' => AppColors.warn,
        'Mecanico' || 'Auxiliar' || 'Funileiro' => AppColors.info,
        _ => AppColors.ink3,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AtivoChip extends StatelessWidget {
  const _AtivoChip({required this.ativo});
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ativo ? AppColors.okSoft : AppColors.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: ativo ? AppColors.ok : AppColors.ink3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            ativo ? 'ATIVO' : 'INATIVO',
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ativo ? AppColors.ok : AppColors.ink3,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cards ──────────────────────────────────────────────────────────────────────

class _DadosPessoaisCard extends StatelessWidget {
  const _DadosPessoaisCard(
      {required this.funcionario, required this.onEditar});
  final Funcionario funcionario;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final cargoLabel =
        _cargoLabels[funcionario.cargo] ?? funcionario.cargo;
    return _Card(
      icon: Icons.person_outline,
      title: 'Perfil',
      subtitle: 'Dados pessoais e contato',
      action: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 16),
        onPressed: onEditar,
        color: AppColors.ink3,
        tooltip: 'Editar',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _FieldRow(label: 'NOME COMPLETO', value: funcionario.nome),
            _FieldRow(label: 'E-MAIL', value: funcionario.email),
            if (funcionario.telefone != null)
              _FieldRow(label: 'TELEFONE', value: funcionario.telefone!),
            _FieldRow(label: 'CARGO', value: cargoLabel),
            _FieldRow(
              label: 'DATA DE ADMISSÃO',
              value: _fmtDate(funcionario.criadoEm),
              last: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _OficinasCard extends StatelessWidget {
  const _OficinasCard({required this.oficinas});
  final List<OficinaRef> oficinas;

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: Icons.store_outlined,
      title: 'Oficinas · ${oficinas.length}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: oficinas.isEmpty
            ? Text(
                'Nenhuma oficina atribuída.',
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    color: AppColors.ink3,
                    fontStyle: FontStyle.italic),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 6,
                children: oficinas.map((o) => _OficinaTag(o.nome)).toList(),
              ),
      ),
    );
  }
}

class _OficinaTag extends StatelessWidget {
  const _OficinaTag(this.nome);
  final String nome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        nome,
        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ink2),
      ),
    );
  }
}

class _RemuneracaoCard extends StatelessWidget {
  const _RemuneracaoCard({required this.funcionario});
  final Funcionario funcionario;

  PaymentType get _paymentType => switch (funcionario.tipoRemuneracao) {
        'Fixo' => PaymentType.fixo,
        'Socio' => PaymentType.socio,
        _ => PaymentType.comissao,
      };

  @override
  Widget build(BuildContext context) {
    final tipo = switch (funcionario.tipoRemuneracao) {
      'Fixo' => 'Salário fixo',
      'Socio' => 'Sócio',
      'Porcentagem' => 'Comissão sobre OS',
      _ => funcionario.tipoRemuneracao,
    };

    return _Card(
      icon: Icons.payments_outlined,
      title: 'Forma de pagamento',
      subtitle: 'Como este funcionário é remunerado',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaymentBadge(
              type: _paymentType,
              percent: funcionario.porcentagem?.toInt(),
            ),
            const SizedBox(height: 14),
            _FieldRow(label: 'TIPO', value: tipo),
            if (funcionario.salario != null)
              _FieldRow(
                label: 'SALÁRIO',
                value: _fmtBrl(funcionario.salario!),
              ),
            if (funcionario.porcentagem != null)
              _FieldRow(
                label: '% SOBRE OS',
                value: '${funcionario.porcentagem!.toStringAsFixed(0)}%',
              ),
            if (funcionario.tipoRemuneracao == 'Porcentagem')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_outlined,
                          size: 14, color: AppColors.accentDark),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Comissão calculada sobre serviços fechados',
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 11,
                            color: AppColors.accentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}

// ── Shared primitives ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.ink3),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle case final s?)
                        Text(
                          s,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 11,
                            color: AppColors.ink3,
                          ),
                        ),
                    ],
                  ),
                ),
                if (action case final a?) a,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          child,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink3,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout ──────────────────────────────────────────────────────────────

class _MobileLayout extends StatefulWidget {
  const _MobileLayout({
    required this.funcionario,
    required this.onEditar,
    required this.onResetarSenha,
  });
  final Funcionario funcionario;
  final VoidCallback onEditar;
  final VoidCallback onResetarSenha;

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final f = widget.funcionario;
    return Column(
      children: [
        _MobileSubHeader(funcionario: f),
        _MobileKpiStrip(funcionario: f),
        _MobileTabBar(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: switch (_tab) {
              0 => _MobilePerfilContent(funcionario: f, onEditar: widget.onEditar),
              1 => _MobilePagamentoContent(funcionario: f),
              2 => _MobileOficinasContent(oficinas: f.oficinas),
              _ => const SizedBox(),
            },
          ),
        ),
      ],
    );
  }
}

// ── Mobile sub-header (dark strip below top bar) ───────────────────────────────

class _MobileSubHeader extends StatelessWidget {
  const _MobileSubHeader({required this.funcionario});
  final Funcionario funcionario;

  String get _initials {
    final parts = funcionario.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return funcionario.nome.substring(0, funcionario.nome.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cargoLabel = _cargoLabels[funcionario.cargo] ?? funcionario.cargo;
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GamaAvatar(initials: _initials, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CargoChip(cargo: funcionario.cargo, label: cargoLabel),
                    const SizedBox(width: 6),
                    _AtivoChip(ativo: funcionario.ativo),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  cargoLabel,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.sidebarText),
                    const SizedBox(width: 5),
                    Text(
                      'desde ${_fmtDate(funcionario.criadoEm)}',
                      style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 11, color: AppColors.sidebarText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Mobile KPI strip ───────────────────────────────────────────────────────────

class _MobileKpiStrip extends StatelessWidget {
  const _MobileKpiStrip({required this.funcionario});
  final Funcionario funcionario;

  String get _remuneracaoLabel {
    if (funcionario.tipoRemuneracao == 'Porcentagem' && funcionario.porcentagem != null) {
      return '${funcionario.porcentagem!.toInt()}%';
    }
    return switch (funcionario.tipoRemuneracao) {
      'Fixo'  => 'FIXO',
      'Socio' => 'SÓCIO',
      _       => '—',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _MobileKpiCell(
            label: 'CARGO',
            value: (_cargoLabels[funcionario.cargo] ?? funcionario.cargo).toUpperCase(),
          ),
          _MobileKpiDivider(),
          _MobileKpiCell(
            label: 'REMUNERAÇÃO',
            value: _remuneracaoLabel,
          ),
          _MobileKpiDivider(),
          _MobileKpiCell(
            label: 'OFICINAS',
            value: '${funcionario.oficinas.length}',
          ),
        ],
      ),
    );
  }
}

class _MobileKpiCell extends StatelessWidget {
  const _MobileKpiCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MobileKpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.line,
        margin: const EdgeInsets.symmetric(horizontal: 14),
      );
}

// ── Mobile tab bar ─────────────────────────────────────────────────────────────

class _MobileTabBar extends StatelessWidget {
  const _MobileTabBar({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  static const _labels = ['Perfil', 'Pagamento', 'Oficinas'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[i],
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.accent : AppColors.ink3,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Mobile tab contents ────────────────────────────────────────────────────────

class _MobilePerfilContent extends StatelessWidget {
  const _MobilePerfilContent({required this.funcionario, required this.onEditar});
  final Funcionario funcionario;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final cargoLabel = _cargoLabels[funcionario.cargo] ?? funcionario.cargo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.ink3),
                  const SizedBox(width: 8),
                  Text(
                    'Perfil',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onEditar,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Editar',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  _MobileFieldRow(label: 'NOME COMPLETO', value: funcionario.nome),
                  _MobileFieldRow(label: 'E-MAIL', value: funcionario.email),
                  if (funcionario.telefone != null)
                    _MobileFieldRow(label: 'TELEFONE', value: funcionario.telefone!),
                  _MobileFieldRow(label: 'CARGO', value: cargoLabel),
                  _MobileFieldRow(
                    label: 'ADMISSÃO',
                    value: _fmtDate(funcionario.criadoEm),
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MobilePagamentoContent extends StatelessWidget {
  const _MobilePagamentoContent({required this.funcionario});
  final Funcionario funcionario;

  PaymentType get _paymentType => switch (funcionario.tipoRemuneracao) {
        'Fixo'  => PaymentType.fixo,
        'Socio' => PaymentType.socio,
        _       => PaymentType.comissao,
      };

  @override
  Widget build(BuildContext context) {
    final tipoLabel = switch (funcionario.tipoRemuneracao) {
      'Fixo'        => 'Salário fixo',
      'Socio'       => 'Sócio',
      'Porcentagem' => 'Comissão sobre OS',
      _             => funcionario.tipoRemuneracao,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: AppColors.ink3),
                  const SizedBox(width: 8),
                  Text(
                    'Pagamento',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PaymentBadge(
                    type: _paymentType,
                    percent: funcionario.porcentagem?.toInt(),
                  ),
                  const SizedBox(height: 14),
                  _MobileFieldRow(label: 'TIPO', value: tipoLabel),
                  if (funcionario.salario != null)
                    _MobileFieldRow(
                      label: 'SALÁRIO',
                      value: _fmtBrl(funcionario.salario!),
                    ),
                  if (funcionario.porcentagem != null)
                    _MobileFieldRow(
                      label: '% SOBRE OS',
                      value: '${funcionario.porcentagem!.toStringAsFixed(0)}%',
                      last: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtBrl(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }
}

class _MobileOficinasContent extends StatelessWidget {
  const _MobileOficinasContent({required this.oficinas});
  final List<OficinaRef> oficinas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.store_outlined, size: 16, color: AppColors.ink3),
                  const SizedBox(width: 8),
                  Text(
                    'Oficinas · ${oficinas.length}',
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: oficinas.isEmpty
                  ? Text(
                      'Nenhuma oficina atribuída.',
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 13,
                        color: AppColors.ink3,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: oficinas.map((o) => _OficinaTag(o.nome)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileFieldRow extends StatelessWidget {
  const _MobileFieldRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.ink3),
          const SizedBox(height: 12),
          Text(
            'Erro ao carregar ficha do funcionário',
            style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
