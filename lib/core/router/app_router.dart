import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/select_group_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash      = '/';
  static const login       = '/login';
  static const selectGroup = '/select-group';
  static const home        = '/home';
}

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
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final auth = authAsync.valueOrNull;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final isPending = auth?.pendingGroupSelection ?? false;

      if (isPending && loc != AppRoutes.selectGroup) return AppRoutes.selectGroup;
      if (isAuthenticated && (loc == AppRoutes.login || loc == AppRoutes.splash)) return AppRoutes.home;
      if (!isAuthenticated && !isPending && loc != AppRoutes.login) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,      builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,       builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.selectGroup, builder: (_, _) => const SelectGroupScreen()),
      GoRoute(path: AppRoutes.home,        builder: (_, _) => const HomeScreen()),
    ],
  );
});
