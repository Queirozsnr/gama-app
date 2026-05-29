import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../../../shared/state/top_bar_scope.dart';
import '../../../shared/widgets/chips/payment_badge.dart';
import '../../../shared/widgets/gama_avatar.dart';
import '../../../shared/widgets/gama_confirm_dialog.dart';
import '../../../shared/widgets/gama_fab.dart';
import '../../../shared/widgets/gama_list_tile.dart';
import '../../../shared/widgets/gama_snack_bar.dart';
import '../domain/funcionario.dart';
import '../domain/remuneracao.dart';
import 'funcionarios_notifier.dart';
import 'widgets/funcionario_card.dart';
import 'widgets/funcionario_form_dialog.dart';

class FuncionariosScreen extends ConsumerStatefulWidget {
  const FuncionariosScreen({super.key});

  @override
  ConsumerState<FuncionariosScreen> createState() => _FuncionariosScreenState();
}

class _FuncionariosScreenState extends ConsumerState<FuncionariosScreen>
    with TopBarSlotMixin<FuncionariosScreen> {
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSlot();
  }

  void _syncSlot() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final auth = ref.read(authNotifierProvider).valueOrNull;
    final oficinas = auth?.availableOficinas ?? [];
    final nome = oficinas.cast<OficinaItem?>().firstWhere(
      (o) => o!.id == auth?.oficinaId,
      orElse: () => null,
    )?.nome;
    setTopBarSlot(TopBarSlot(
      pageTitle: 'Funcionários',
      mobileStyle: MobileTopBarStyle.dark,
      mobileSubtitle: nome != null ? '• $nome' : null,
      searchController: isDesktop ? _searchController : null,
      searchHint: isDesktop ? 'Buscar por nome ou e-mail…' : null,
      onSearchChanged: isDesktop
          ? (v) => ref.read(funcionariosNotifierProvider.notifier).buscar(v)
          : null,
      action: FilledButton.icon(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined, size: 17),
        label: const Text('Novo funcionário'),
      ),
      mobileAction: IconButton(
        onPressed: _toggleSearch,
        icon: Icon(
          _searchOpen ? Icons.close : Icons.search,
          color: _searchOpen ? AppColors.accent : Colors.white,
          size: 20,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    ));
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchController.clear();
      ref.read(funcionariosNotifierProvider.notifier).buscar(null);
    }
    _syncSlot();
  }

  @override
  void dispose() {
    super.dispose(); // mixin clears slot, TopBar will rebuild next frame
    // Defer disposal so the TopBar finishes rebuilding before the controller is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchController.dispose());
  }

  Future<void> _openForm({Funcionario? funcionario}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => FuncionarioFormDialog(funcionario: funcionario),
    );
    if (result == true && mounted) {
      GamaSnackBar.success(
        context,
        funcionario == null ? 'Funcionário criado com sucesso!' : 'Funcionário atualizado!',
      );
    }
  }

  Future<void> _excluir(Funcionario f) async {
    final confirmar = await GamaConfirmDialog.show(
      context,
      title: 'Excluir funcionário',
      message: 'Deseja excluir "${f.nome}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (confirmar && mounted) {
      try {
        await ref.read(funcionariosNotifierProvider.notifier).excluir(f.id);
        if (mounted) GamaSnackBar.success(context, 'Funcionário removido.');
      } catch (_) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao excluir funcionário.');
      }
    }
  }

  Future<void> _resetarSenha(Funcionario f) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => GamaConfirmDialog(
        title: 'Resetar senha',
        message: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            children: [
              const TextSpan(text: 'Resetar a senha de '),
              TextSpan(text: f.nome, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const TextSpan(text: ' para '),
              const TextSpan(text: 'gama123', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        confirmLabel: 'Resetar',
      ),
    ) == true;
    if (confirmar && mounted) {
      try {
        await ref.read(funcionariosNotifierProvider.notifier).resetarSenha(f.id);
        if (mounted) GamaSnackBar.success(context, 'Senha resetada para "gama123".');
      } catch (_) {
        if (mounted) GamaSnackBar.error(context, 'Erro ao resetar senha.');
      }
    }
  }

  String _initials(Funcionario f) {
    final parts = f.nome.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return f.nome.substring(0, f.nome.length.clamp(0, 2)).toUpperCase();
  }

  PaymentType _paymentType(Funcionario f) => switch (f.tipoRemuneracao) {
        'Fixo'  => PaymentType.fixo,
        'Socio' => PaymentType.socio,
        _       => PaymentType.comissao,
      };


  @override
  Widget build(BuildContext context) {
    final funcionariosAsync = ref.watch(funcionariosNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return funcionariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('Erro ao carregar funcionários',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.invalidate(funcionariosNotifierProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (funcionarios) {
        if (funcionarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppColors.border),
                const SizedBox(height: 16),
                const Text('Nenhum funcionário encontrado',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('Toque no + para adicionar o primeiro',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        if (isDesktop) {
          return RefreshIndicator(
            onRefresh: () => ref.read(funcionariosNotifierProvider.notifier).buscar(
                  _searchController.text.isEmpty ? null : _searchController.text,
                ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: funcionarios.length,
              itemBuilder: (_, i) {
                final f = funcionarios[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GamaListTile(
                    leading: GamaAvatar(initials: _initials(f), size: 44),
                    title: f.nome,
                    subtitle: cargoLabel(f.cargo).toUpperCase(),
                    details: [
                      GamaListDetail(icon: Icons.email_outlined, text: f.email),
                      if (f.telefone != null)
                        GamaListDetail(icon: Icons.phone_outlined, text: f.telefone!),
                    ],
                    trailing: SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          PaymentBadge(
                            type: _paymentType(f),
                            percent: f.porcentagem?.toInt(),
                          ),
                          const Spacer(),
                          _AtivoChip(ativo: f.ativo),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz,
                                size: 18, color: AppColors.ink3),
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'senha',
                                child: Row(children: [
                                  const Icon(Icons.lock_reset_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Resetar senha'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'excluir',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.danger),
                                  const SizedBox(width: 8),
                                  Text('Excluir',
                                      style:
                                          TextStyle(color: AppColors.danger)),
                                ]),
                              ),
                            ],
                            onSelected: (v) {
                              if (v == 'senha') _resetarSenha(f);
                              if (v == 'excluir') _excluir(f);
                            },
                          ),
                        ],
                      ),
                    ),
                    onTap: () => context.go(
                      AppRoutes.funcionariosDetalhe.replaceAll(':id', '${f.id}'),
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Mobile
        return Stack(
          children: [
            Column(
              children: [
                if (_searchOpen)
                  _MobileSearchRow(
                    controller: _searchController,
                    hint: 'Buscar por nome ou e-mail…',
                    onChanged: (v) => ref
                        .read(funcionariosNotifierProvider.notifier)
                        .buscar(v),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref
                        .read(funcionariosNotifierProvider.notifier)
                        .buscar(_searchController.text.isEmpty
                            ? null
                            : _searchController.text),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 180,
                      ),
                      itemCount: funcionarios.length,
                      itemBuilder: (_, i) {
                        final f = funcionarios[i];
                        return FuncionarioCard(
                          funcionario: f,
                          onTap: () => context.go(
                            AppRoutes.funcionariosDetalhe
                                .replaceAll(':id', '${f.id}'),
                          ),
                          onLongPress: () => _excluir(f),
                          onResetarSenha: () => _resetarSenha(f),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: GamaFab(
                label: 'Novo funcionário',
                icon: Icons.person_add_outlined,
                onTap: () => _openForm(),
              ),
            ),
          ],
        );
      },
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
      child: Text(
        ativo ? 'ATIVO' : 'INATIVO',
        style: TextStyle(fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: ativo ? AppColors.ok : AppColors.ink3,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MobileSearchRow extends StatelessWidget {
  const _MobileSearchRow({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.sidebarLine,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppColors.sidebarText),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.sidebarText),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
