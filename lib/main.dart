import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/auth/providers/auth_provider.dart';
import 'presentation/customer/providers/cart_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized on native layer — safe to ignore
  }

  runApp(const LengthFactoryApp());
}

class LengthFactoryApp extends StatelessWidget {
  const LengthFactoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global: drives role-based routing across the whole app.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Scoped logically to the Customer flow, but kept at root so
        // it survives navigation between Home -> Product Details -> Cart.
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: AppRouterProvider(
        lightTheme: _lightThemeRef,
        darkTheme: _darkThemeRef,
        themeMode: ThemeMode.system,
      ),
    );
  }
}

// Static getters kept outside build() so AppTheme is computed once
// (GoogleFonts text themes are relatively expensive to rebuild).
final _lightThemeRef = AppTheme.light;
final _darkThemeRef = AppTheme.dark;
