import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/plan/plan_limit_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../core/update/update_dialog.dart';
import '../../core/update/update_notifier.dart';
import '../../core/utils/jwt_decoder.dart';
import '../../features/assinatura/presentation/assinatura_notifier.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../state/top_bar_scope.dart';
import '../widgets/gama_snack_bar.dart';
import 'gama_bottom_nav.dart';
import 'gama_sidebar.dart';
import 'gama_top_bar.dart';

// Number of shell branches — must match the StatefulShellRoute in app_router.
const _kBranchCount = 5;

class GamaScaffold extends ConsumerStatefulWidget {
  const GamaScaffold({
    super.key,
    required this.navigationShell,
    this.pageTitle,
    this.pageSubtitle,
  });

  final StatefulNavigationShell navigationShell;
  final String? pageTitle;
  final String? pageSubtitle;

  @override
  ConsumerState<GamaScaffold> createState() => _GamaScaffoldState();
}

class _GamaScaffoldState extends ConsumerState<GamaScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool? _sidebarCollapsed; // null = segue breakpoint automático

  // One notifier per branch — screens in inactive branches push to their own
  // notifier and don't bleed into the active branch's topbar.
  final _branchNotifiers = List.generate(_kBranchCount, (_) => TopBarNotifier());

  // Tracks the history of tab switches so back can restore the previous tab.
  final _branchHistory = <int>[];
  // Prevents didUpdateWidget from re-recording a history entry when we're
  // already navigating back through history.
  bool _poppingBranch = false;
  Timer? _assinaturaRefreshTimer;

  TopBarNotifier get _activeNotifier =>
      _branchNotifiers[widget.navigationShell.currentIndex];

  @override
  void didUpdateWidget(GamaScaffold old) {
    super.didUpdateWidget(old);
    final newIdx = widget.navigationShell.currentIndex;
    final oldIdx = old.navigationShell.currentIndex;
    if (newIdx != oldIdx) {
      if (_poppingBranch) {
        _poppingBranch = false;
      } else {
        _branchHistory.add(oldIdx);
      }
    }
  }

  void _handleBranchBack() {
    if (_branchHistory.isEmpty) return;
    _poppingBranch = true;
    final prev = _branchHistory.removeLast();
    setState(() {});
    widget.navigationShell.goBranch(prev);
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(updateNotifierProvider.notifier).checkAndDownload();
      });
    }
  }

  @override
  void dispose() {
    _assinaturaRefreshTimer?.cancel();
    for (final n in _branchNotifiers) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(planLimitNotifierProvider, (_, msg) {
      if (msg == null) return;
      GamaSnackBar.error(context, msg);
      ref.read(planLimitNotifierProvider.notifier).clear();
    });

    ref.listen<UpdateDownloadState>(updateNotifierProvider, (_, state) {
      if (state is UpdateReady && mounted) {
        showUpdateDialog(context, state.info, apkPath: state.apkPath);
      }
    });

    ref.listen(planoExpiradoNotifierProvider, (_, msg) {
      if (msg == null) return;
      ref.read(planoExpiradoNotifierProvider.notifier).clear();
      ref.invalidate(assinaturaProvider);
      final token = ref.read(authNotifierProvider).value?.token;
      final isGestor = token != null && JwtDecoder.isGestor(token);
      if (isGestor) {
        context.go('/assinatura');
        GamaSnackBar.error(context, msg);
      } else {
        GamaSnackBar.error(context, 'Plano expirado. Entre em contato com o responsável.');
      }
    });

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final autoCollapsed = isDesktop && width < 1100;
    final sidebarCollapsed = _sidebarCollapsed ?? autoCollapsed;

    // Banner proativo: uma request por sessão, refresh automático a cada 2 min
    // enquanto o banner estiver visível (para sumir sozinho após renovação).
    final expiracaoAviso = ref.watch(assinaturaProvider).whenOrNull(
      data: (d) {
        final dias = d.proximaCobranca.difference(DateTime.now()).inDays;
        return (dias >= 0 && dias <= 3) ? dias : null;
      },
    );

    if (expiracaoAviso != null) {
      _assinaturaRefreshTimer ??= Timer.periodic(const Duration(minutes: 2), (_) {
        ref.invalidate(assinaturaProvider);
      });
    } else {
      _assinaturaRefreshTimer?.cancel();
      _assinaturaRefreshTimer = null;
    }

    // BranchTopBarScope lets the router's navigatorContainerBuilder read the
    // per-branch notifiers and wrap each branch navigator in its own TopBarScope.
    // The outer TopBarScope (used by GamaTopBar) always points to the active branch.
    if (isDesktop) {
      return BranchTopBarScope(
        notifiers: _branchNotifiers,
        child: Scaffold(
          key: _scaffoldKey,
          body: TopBarScope(
            notifier: _activeNotifier,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: sidebarCollapsed ? 64 : 260,
                  child: GamaSidebar(
                    collapsed: sidebarCollapsed,
                    onToggle: () => setState(() => _sidebarCollapsed = !sidebarCollapsed),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GamaTopBar(
                        isDesktop: true,
                        pageTitle: widget.pageTitle,
                        pageSubtitle: widget.pageSubtitle,
                      ),
                      if (expiracaoAviso != null)
                        _ExpiracaoBanner(
                          dias: expiracaoAviso,
                          onTap: () => context.go('/assinatura'),
                        ),
                      Expanded(child: widget.navigationShell),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BranchTopBarScope(
      notifiers: _branchNotifiers,
      child: BackButtonListener(
        onBackButtonPressed: () async {
          if (_branchHistory.isNotEmpty && !GoRouter.of(context).canPop()) {
            _handleBranchBack();
            return true;
          }
          return false;
        },
        child: PopScope(
          canPop: _branchHistory.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBranchBack();
          },
          child: Scaffold(
            key: _scaffoldKey,
            bottomNavigationBar: GamaBottomNav(navigationShell: widget.navigationShell),
            body: TopBarScope(
              notifier: _activeNotifier,
              child: Column(
                children: [
                  GamaTopBar(
                    isDesktop: false,
                    pageTitle: widget.pageTitle,
                    pageSubtitle: widget.pageSubtitle,
                  ),
                  if (expiracaoAviso != null)
                    _ExpiracaoBanner(
                      dias: expiracaoAviso,
                      onTap: () => context.go('/assinatura'),
                    ),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

// ── Banner proativo de expiração ──────────────────────────────────────────────

class _ExpiracaoBanner extends StatelessWidget {
  const _ExpiracaoBanner({required this.dias, required this.onTap});

  final int dias;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = dias == 0
        ? 'Sua assinatura expira hoje.'
        : 'Sua assinatura expira em $dias ${dias == 1 ? 'dia' : 'dias'}.';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: AppColors.warn,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label  Toque para ver o plano →',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
