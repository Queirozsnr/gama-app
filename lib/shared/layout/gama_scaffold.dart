import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/top_bar_scope.dart';
import 'gama_bottom_nav.dart';
import 'gama_sidebar.dart';
import 'gama_top_bar.dart';

// Number of shell branches — must match the StatefulShellRoute in app_router.
const _kBranchCount = 5;

class GamaScaffold extends StatefulWidget {
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
  State<GamaScaffold> createState() => _GamaScaffoldState();
}

class _GamaScaffoldState extends State<GamaScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // One notifier per branch — screens in inactive branches push to their own
  // notifier and don't bleed into the active branch's topbar.
  final _branchNotifiers = List.generate(_kBranchCount, (_) => TopBarNotifier());

  // Tracks the history of tab switches so back can restore the previous tab.
  final _branchHistory = <int>[];
  // Prevents didUpdateWidget from re-recording a history entry when we're
  // already navigating back through history.
  bool _poppingBranch = false;

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
  void dispose() {
    for (final n in _branchNotifiers) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

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
                const SizedBox(width: 260, child: GamaSidebar()),
                Expanded(
                  child: Column(
                    children: [
                      GamaTopBar(
                        isDesktop: true,
                        pageTitle: widget.pageTitle,
                        pageSubtitle: widget.pageSubtitle,
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
