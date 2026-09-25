import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';

class LengthFactoryApp extends StatefulWidget {
  const LengthFactoryApp({super.key});

  @override
  State<LengthFactoryApp> createState() => _LengthFactoryAppState();
}

class _LengthFactoryAppState extends State<LengthFactoryApp> {
  late final AppRouter _appRouter = AppRouter(sl<AuthCubit>());
  late final ThemeData _theme = AppTheme.light;

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: sl<AuthCubit>()),
        BlocProvider<CartCubit>.value(value: sl<CartCubit>()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        // The cart belongs to one customer session only.
        listenWhen: (p, c) => p.user?.uid != c.user?.uid,
        listener: (context, _) => context.read<CartCubit>().clear(),
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: _theme,
          themeMode: ThemeMode.light,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
