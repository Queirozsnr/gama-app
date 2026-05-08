import 'package:flutter/material.dart';
import 'gama_sidebar.dart';
import 'gama_top_bar.dart';

class GamaScaffold extends StatefulWidget {
  const GamaScaffold({
    super.key,
    required this.body,
    this.pageTitle,
    this.pageSubtitle,
    this.topBarAction,
  });

  final Widget body;
  final String? pageTitle;
  final String? pageSubtitle;
  final Widget? topBarAction;

  @override
  State<GamaScaffold> createState() => _GamaScaffoldState();
}

class _GamaScaffoldState extends State<GamaScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final topBar = GamaTopBar(
      isDesktop: isDesktop,
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      pageTitle: widget.pageTitle,
      pageSubtitle: widget.pageSubtitle,
      action: widget.topBarAction,
    );

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        body: Row(
          children: [
            const SizedBox(width: 260, child: GamaSidebar()),
            Expanded(
              child: Column(
                children: [
                  topBar,
                  Expanded(child: widget.body),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const Drawer(width: 260, child: SafeArea(child: GamaSidebar())),
      body: SafeArea(
        child: Column(
          children: [
            topBar,
            Expanded(child: widget.body),
          ],
        ),
      ),
    );
  }
}
