import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/select_group_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/ordens_servico/presentation/ordens_servico_screen.dart';
import '../../features/clientes/presentation/clientes_screen.dart';
import '../../features/veiculos/presentation/veiculos_screen.dart';
import '../../features/estoque/presentation/estoque_screen.dart';
import '../../features/funcionarios/presentation/funcionarios_screen.dart';
import '../../features/pagamentos/presentation/pagamentos_screen.dart';
import '../../features/oficinas/presentation/gerenciar_oficinas_screen.dart';
import '../../shared/layout/gama_scaffold.dart';

abstract final class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const selectGroup    = '/select-group';
  static const home           = '/home';
  static const ordensServico  = '/ordens-servico';
  static const clientes       = '/clientes';
  static const veiculos       = '/veiculos';
  static const estoque        = '/estoque';
  static const funcionarios   = '/funcionarios';
  static const pagamentos        = '/pagamentos';
  static const gerenciarOficinas = '/gerenciar-oficinas';
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
      final isPending = auth?.pendingGroupSelection ?? false;

      if (isPending && loc != AppRoutes.selectGroup) return AppRoutes.selectGroup;
      if (isAuthenticated && (loc == AppRoutes.login || loc == AppRoutes.splash)) {
        final from = state.uri.queryParameters['from'];
        final target = (from != null && from.isNotEmpty) ? Uri.decodeComponent(from) : AppRoutes.home;
        return target;
      }
      if (!isAuthenticated && !isPending && loc != AppRoutes.login) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,      builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,       builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.selectGroup, builder: (_, _) => const SelectGroupScreen()),
      ShellRoute(
        builder: (context, state, child) {
          final location = GoRouterState.of(context).matchedLocation;
          return GamaScaffold(
            pageTitle: _pageTitles[location],
            body: child,
          );
        },
        routes: [
          GoRoute(path: AppRoutes.home,         builder: (_, _) => const HomeScreen()),
          GoRoute(path: AppRoutes.ordensServico, builder: (_, _) => const OrdensServicoScreen()),
          GoRoute(path: AppRoutes.clientes,      builder: (_, _) => const ClientesScreen()),
          GoRoute(path: AppRoutes.veiculos,      builder: (_, _) => const VeiculosScreen()),
          GoRoute(path: AppRoutes.estoque,       builder: (_, _) => const EstoqueScreen()),
          GoRoute(path: AppRoutes.funcionarios,  builder: (_, _) => const FuncionariosScreen()),
          GoRoute(path: AppRoutes.pagamentos,        builder: (_, _) => const PagamentosScreen()),
          GoRoute(path: AppRoutes.gerenciarOficinas, builder: (_, _) => const GerenciarOficinasScreen()),
        ],
      ),
    ],
  );
});
