import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/shared/screens/splash_screen.dart';
import '../../presentation/admin/screens/admin_shell.dart';
import '../../presentation/customer/screens/customer_shell.dart';
import '../../presentation/worker/screens/worker_shell.dart';

/// Centralized route names — avoids "magic string" route paths
/// scattered across the codebase.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const adminHome = '/admin';
  static const customerHome = '/customer';
  static const workerHome = '/worker';
}

/// Builds the app's [GoRouter] with a centralized `redirect` that enforces
/// role-based access: an unauthenticated user can only see auth screens,
/// and an authenticated user is bounced to *their* role's shell even if
/// they manually navigate to another role's path.
GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authProvider,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminShell(),
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (context, state) => const CustomerShell(),
      ),
      GoRoute(
        path: AppRoutes.workerHome,
        builder: (context, state) => const WorkerShell(),
      ),
    ],
    redirect: (context, state) {
      final status = authProvider.status;
      final loc = state.matchedLocation;

      // Still resolving Firebase auth state -> stay on splash.
      if (status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;

      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // status == authenticated
      final roleHome = switch (authProvider.currentUser?.role) {
        'admin' => AppRoutes.adminHome,
        'worker' => AppRoutes.workerHome,
        _ => AppRoutes.customerHome,
      };

      final onCorrectRoleHome = loc.startsWith(roleHome);
      if (isAuthRoute || loc == AppRoutes.splash || !onCorrectRoleHome) {
        return roleHome;
      }
      return null;
    },
  );
}

/// Convenience widget that wires [AuthProvider] (already provided above
/// it in the widget tree) into [buildRouter] via [MaterialApp.router].
class AppRouterProvider extends StatelessWidget {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;

  const AppRouterProvider({
    super.key,
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final router = buildRouter(authProvider);

    return MaterialApp.router(
      title: 'Length Factory',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
