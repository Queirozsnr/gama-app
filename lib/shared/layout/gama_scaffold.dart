import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/top_bar_scope.dart';
import 'gama_bottom_nav.dart';
import 'gama_sidebar.dart';
import 'gama_top_bar.dart';

class GamaScaffold extends StatefulWidget {
  const GamaScaffold({
    super.key,
    required this.body,
    this.pageTitle,
    this.pageSubtitle,
  });

  final Widget body;
  final String? pageTitle;
  final String? pageSubtitle;

  @override
  State<GamaScaffold> createState() => _GamaScaffoldState();
}

class _GamaScaffoldState extends State<GamaScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _topBarNotifier = TopBarNotifier();
  final List<String> _history = [];

  void _updateHistory(String loc) {
    if (_history.isEmpty) {
      _history.add(loc);
      return;
    }
    if (_history.last == loc) return;
    final existingIdx = _history.lastIndexOf(loc);
    if (existingIdx >= 0) {
      // voltando para rota já visitada — trunca o histórico
      _history.removeRange(existingIdx + 1, _history.length);
    } else {
      _history.add(loc);
    }
  }

  Future<bool> _onBackPressed() async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return true;
    }
    if (_history.length > 1) {
      _history.removeLast();
      context.go(_history.last);
      return true;
    }
    return false; // no primeiro item do histórico: deixa o sistema fechar
  }

  @override
  void dispose() {
    _topBarNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        body: TopBarScope(
          notifier: _topBarNotifier,
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
                    Expanded(child: widget.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final loc = GoRouterState.of(context).matchedLocation;
    _updateHistory(loc);

    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        bottomNavigationBar: const GamaBottomNav(),
        body: TopBarScope(
          notifier: _topBarNotifier,
          child: SafeArea(
            child: Column(
              children: [
                GamaTopBar(
                  isDesktop: false,
                  pageTitle: widget.pageTitle,
                  pageSubtitle: widget.pageSubtitle,
                ),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
