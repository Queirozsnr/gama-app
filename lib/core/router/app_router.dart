import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/select_group_screen.dart';
import '../../features/auth/presentation/select_oficina_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/ordens_servico/presentation/ordens_servico_screen.dart';
import '../../features/ordens_servico/presentation/os_detalhe_screen.dart';
import '../../features/ordens_servico/presentation/os_nova_screen.dart';
import '../../features/clientes/presentation/clientes_screen.dart';
import '../../features/veiculos/presentation/veiculos_screen.dart';
import '../../features/estoque/presentation/estoque_screen.dart';
import '../../features/funcionarios/presentation/funcionarios_screen.dart';
import '../../features/pagamentos/presentation/pagamentos_screen.dart';
import '../../features/oficinas/presentation/gerenciar_oficinas_screen.dart';
import '../../features/auth/presentation/trocar_senha_screen.dart';
import '../../shared/layout/gama_scaffold.dart';

abstract final class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const selectGroup    = '/select-group';
  static const home           = '/home';
  static const ordensServico       = '/ordens-servico';
  static const ordensServicoDetalhe = '/ordens-servico/:id';
  static const clientes       = '/clientes';
  static const veiculos       = '/veiculos';
  static const estoque        = '/estoque';
  static const funcionarios   = '/funcionarios';
  static const pagamentos        = '/pagamentos';
  static const gerenciarOficinas = '/gerenciar-oficinas';
  static const selectOficina    = '/select-oficina';
  static const trocarSenha      = '/trocar-senha';
}

const _pageTitles = <String, String>{
  AppRoutes.home:          'Dashboard',
  AppRoutes.ordensServico: 'Ordens de Serviço',
  AppRoutes.clientes:      'Clientes',
  AppRoutes.veiculos:      'Veículos',
  AppRoutes.estoque:       'Estoque',
  AppRoutes.funcionarios:  'Funcionários',
  AppRoutes.pagamentos:        'Pagamentos',
  AppRoutes.gerenciarOficinas: 'Gerenciar Oficinas',
};

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }
}

Page<void> Function(BuildContext, GoRouterState) _fade(Widget Function(BuildContext, GoRouterState) builder) {
  return (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: builder(context, state),
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      if (authAsync.isLoading) {
        if (loc == AppRoutes.splash) return null;
        final encoded = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.splash}?from=$encoded';
      }

      final auth = authAsync.valueOrNull;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final isPendingGroup = auth?.pendingGroupSelection ?? false;
      final isPendingOficina = auth?.pendingOficinaSelection ?? false;

      final isPendingPassword = auth?.pendingPasswordChange ?? false;

      if (isPendingGroup && loc != AppRoutes.selectGroup) return AppRoutes.selectGroup;
      if (isPendingOficina && loc != AppRoutes.selectOficina) return AppRoutes.selectOficina;
      if (isPendingPassword && loc != AppRoutes.trocarSenha) return AppRoutes.trocarSenha;
      if (isAuthenticated && !isPendingPassword && (loc == AppRoutes.login || loc == AppRoutes.splash || loc == AppRoutes.selectGroup || loc == AppRoutes.selectOficina || loc == AppRoutes.trocarSenha)) {
        final from = state.uri.queryParameters['from'];
        final target = (from != null && from.isNotEmpty) ? Uri.decodeComponent(from) : AppRoutes.home;
        return target;
      }
      if (!isAuthenticated && !isPendingGroup && !isPendingOficina && loc != AppRoutes.login) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,        pageBuilder: _fade((ctx, st) => const SplashScreen())),
      GoRoute(path: AppRoutes.login,         pageBuilder: _fade((ctx, st) => const LoginScreen())),
      GoRoute(path: AppRoutes.selectGroup,   pageBuilder: _fade((ctx, st) => const SelectGroupScreen())),
      GoRoute(path: AppRoutes.selectOficina, pageBuilder: _fade((ctx, st) => const SelectOficinaScreen())),
      GoRoute(path: AppRoutes.trocarSenha,   pageBuilder: _fade((ctx, st) => const TrocarSenhaScreen())),
      ShellRoute(
        builder: (context, state, child) => GamaScaffold(
          pageTitle: _pageTitles[GoRouterState.of(context).matchedLocation],
          body: child,
        ),
        routes: [
          GoRoute(path: AppRoutes.home,              pageBuilder: _fade((ctx, st) => const HomeScreen())),
          GoRoute(
            path: AppRoutes.ordensServico,
            pageBuilder: _fade((ctx, st) => const OrdensServicoScreen()),
            routes: [
              GoRoute(
                path: 'nova',
                pageBuilder: _fade((ctx, st) => const OsNovaScreen()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: _fade((ctx, st) => OsDetalheScreen(osId: int.parse(st.pathParameters['id']!))),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.clientes,          pageBuilder: _fade((ctx, st) => const ClientesScreen())),
          GoRoute(path: AppRoutes.veiculos,          pageBuilder: _fade((ctx, st) => const VeiculosScreen())),
          GoRoute(path: AppRoutes.estoque,           pageBuilder: _fade((ctx, st) => const EstoqueScreen())),
          GoRoute(path: AppRoutes.funcionarios,      pageBuilder: _fade((ctx, st) => const FuncionariosScreen())),
          GoRoute(path: AppRoutes.pagamentos,        pageBuilder: _fade((ctx, st) => const PagamentosScreen())),
          GoRoute(path: AppRoutes.gerenciarOficinas, pageBuilder: _fade((ctx, st) => const GerenciarOficinasScreen())),
        ],
      ),
    ],
  );
});
