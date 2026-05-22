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

    return PopScope(
      canPop: loc == '/home',
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          context.go('/home');
        }
      },
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
