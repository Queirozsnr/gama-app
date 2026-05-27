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
import '../../features/clientes/presentation/cliente_detalhe_screen.dart';
import '../../features/veiculos/presentation/veiculos_screen.dart';
import '../../features/veiculos/presentation/veiculo_detalhe_screen.dart';
import '../../features/estoque/presentation/estoque_screen.dart';
import '../../features/estoque/presentation/fornecedores_screen.dart';
import '../../features/estoque/presentation/novo_produto_screen.dart';
import '../../features/estoque/presentation/produto_detalhe_screen.dart';
import '../../features/estoque/domain/estoque.dart';
import '../../features/funcionarios/presentation/funcionarios_screen.dart';
import '../../features/funcionarios/presentation/funcionario_detalhe_screen.dart';
import '../../features/pagamentos/presentation/pagamentos_screen.dart';
import '../../features/receitas/presentation/receitas_screen.dart';
import '../../features/oficinas/presentation/gerenciar_oficinas_screen.dart';
import '../../features/oficinas/presentation/configuracoes_oficina_screen.dart';
import '../../features/auth/presentation/trocar_senha_screen.dart';
import '../../features/admin/presentation/admin_screen.dart';
import '../../shared/layout/gama_scaffold.dart';
import '../../shared/state/top_bar_scope.dart';

abstract final class AppRoutes {
  static const splash         = '/';
  static const login          = '/login';
  static const selectGroup    = '/select-group';
  static const home           = '/home';
  static const ordensServico        = '/ordens-servico';
  static const ordensServicoNova    = '/ordens-servico/nova';
  static const ordensServicoDetalhe = '/ordens-servico/:id';
  static const clientes         = '/clientes';
  static const clientesDetalhe  = '/clientes/:id';
  static const veiculos        = '/veiculos';
  static const veiculosDetalhe = '/veiculos/:id';
  static const estoque        = '/estoque';
  static const fornecedores   = '/fornecedores';
  static const funcionarios        = '/funcionarios';
  static const funcionariosDetalhe = '/funcionarios/:id';
  static const pagamentos        = '/pagamentos';
  static const receitas          = '/receitas';
  static const gerenciarOficinas    = '/gerenciar-oficinas';
  static const configuracoesOficina = '/configuracoes-oficina';
  static const admin             = '/admin';
  static const selectOficina    = '/select-oficina';
  static const trocarSenha      = '/trocar-senha';
  static const estoqueProdutoNovo    = '/estoque/produto/novo';
  static const estoqueProdutoDetalhe = '/estoque/produto/:id';
  static const estoqueProdutoEditar  = '/estoque/produto/:id/editar';
}

const _pageTitles = <String, String>{
  AppRoutes.home:          'Painel',
  AppRoutes.ordensServico: 'Ordens de Serviço',
  AppRoutes.clientes:      'Clientes',
  AppRoutes.veiculos:      'Veículos',
  AppRoutes.estoque:       'Estoque',
  AppRoutes.fornecedores:  'Fornecedores',
  AppRoutes.funcionarios:  'Funcionários',
  AppRoutes.pagamentos:        'Pagamentos',
  AppRoutes.receitas:          'Receitas',
  AppRoutes.gerenciarOficinas:    'Gerenciar Oficinas',
  AppRoutes.configuracoesOficina: 'Configurações da Oficina',
  AppRoutes.admin: 'Admin',
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
      StatefulShellRoute(
        navigatorContainerBuilder: (context, shell, children) {
          final notifiers = BranchTopBarScope.of(context);
          return IndexedStack(
            index: shell.currentIndex,
            children: [
              for (var i = 0; i < children.length; i++)
                TopBarScope(notifier: notifiers[i], child: children[i]),
            ],
          );
        },
        builder: (context, state, navigationShell) => GamaScaffold(
          navigationShell: navigationShell,
          pageTitle: _pageTitles[GoRouterState.of(context).matchedLocation],
        ),
        branches: [
          // Branch 0 — Painel
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              pageBuilder: _fade((ctx, st) => const HomeScreen()),
            ),
          ]),

          // Branch 1 — Ordens de Serviço
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.ordensServico,
              pageBuilder: _fade((ctx, st) => const OrdensServicoScreen()),
              routes: [
                GoRoute(
                  path: 'nova',
                  pageBuilder: _fade((ctx, st) => OsNovaScreen(clienteIdInicial: st.extra as int?)),
                ),
                GoRoute(
                  path: ':id',
                  pageBuilder: _fade((ctx, st) => OsDetalheScreen(osId: int.parse(st.pathParameters['id']!))),
                ),
              ],
            ),
          ]),

          // Branch 2 — Clientes
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.clientes,
              pageBuilder: _fade((ctx, st) => const ClientesScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: _fade((ctx, st) => ClienteDetalheScreen(clienteId: int.parse(st.pathParameters['id']!))),
                ),
              ],
            ),
          ]),

          // Branch 3 — Estoque
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.estoque,
              pageBuilder: _fade((ctx, st) => const EstoqueScreen()),
              routes: [
                GoRoute(
                  path: 'produto/novo',
                  pageBuilder: _fade((ctx, st) => const NovoProdutoScreen()),
                ),
                GoRoute(
                  path: 'produto/:id',
                  pageBuilder: _fade((ctx, st) => ProdutoDetalheScreen(produto: st.extra! as ProdutoListagem)),
                  routes: [
                    GoRoute(
                      path: 'editar',
                      pageBuilder: _fade((ctx, st) => NovoProdutoScreen(produto: st.extra! as ProdutoListagem)),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.fornecedores,
              pageBuilder: _fade((ctx, st) => const FornecedoresScreen()),
            ),
          ]),

          // Branch 4 — Mais (Veículos, Funcionários, Pagamentos, etc.)
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.veiculos,
              pageBuilder: _fade((ctx, st) => const VeiculosScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: _fade((ctx, st) => VeiculoDetalheScreen(veiculoId: int.parse(st.pathParameters['id']!))),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.funcionarios,
              pageBuilder: _fade((ctx, st) => const FuncionariosScreen()),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: _fade((ctx, st) => FuncionarioDetalheScreen(funcionarioId: int.parse(st.pathParameters['id']!))),
                ),
              ],
            ),
            GoRoute(path: AppRoutes.pagamentos,        pageBuilder: _fade((ctx, st) => const PagamentosScreen())),
            GoRoute(path: AppRoutes.receitas,          pageBuilder: _fade((ctx, st) => const ReceitasScreen())),
            GoRoute(path: AppRoutes.gerenciarOficinas,    pageBuilder: _fade((ctx, st) => const GerenciarOficinasScreen())),
            GoRoute(path: AppRoutes.configuracoesOficina, pageBuilder: _fade((ctx, st) => const ConfiguracoesOficinaScreen())),
            GoRoute(path: AppRoutes.admin,                pageBuilder: _fade((ctx, st) => const AdminScreen())),
          ]),
        ],
      ),
    ],
  );
});
