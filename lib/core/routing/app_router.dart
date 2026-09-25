import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/shell/presentation/admin_shell.dart';
import '../../features/shell/presentation/customer_shell.dart';
import '../../features/shell/presentation/worker_shell.dart';
import 'app_routes.dart';

export 'app_routes.dart';

/// Turns a Cubit stream into a [Listenable] for GoRouter's refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Builds the app router once. The redirect enforces role-based access:
/// unauthenticated users only see auth screens, authenticated users are
/// always bounced to *their* role's shell.
class AppRouter {
  final AuthCubit authCubit;
  late final GoRouter router;
  late final GoRouterRefreshStream _refresh;

  AppRouter(this.authCubit) {
    _refresh = GoRouterRefreshStream(authCubit.stream);
    router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: _refresh,
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
        GoRoute(path: AppRoutes.adminHome, builder: (_, __) => const AdminShell()),
        GoRoute(path: AppRoutes.customerHome, builder: (_, __) => const CustomerShell()),
        GoRoute(path: AppRoutes.workerHome, builder: (_, __) => const WorkerShell()),
      ],
      redirect: (context, state) => redirectFor(authCubit.state, state.matchedLocation),
    );
  }

  /// Pure redirect logic (unit-testable).
  static String? redirectFor(AuthState auth, String location) {
    if (auth.status == AuthStatus.unknown) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isAuthRoute = location == AppRoutes.login || location == AppRoutes.register;

    if (auth.status == AuthStatus.unauthenticated) {
      return isAuthRoute ? null : AppRoutes.login;
    }

    final user = auth.user!;
    final home = user.isAdmin
        ? AppRoutes.adminHome
        : user.isWorker
            ? AppRoutes.workerHome
            : AppRoutes.customerHome;

    if (!location.startsWith(home)) return home;
    return null;
  }

  void dispose() {
    _refresh.dispose();
    router.dispose();
  }
}
