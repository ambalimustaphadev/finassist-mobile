import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/auth_gate.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/shell/presentation/screens/main_shell_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

/// Named routes for FinAssist.
abstract final class AppRoutes {
  /// The app's initial route — reactively shows Login or the main shell
  /// depending on auth state. See [AuthGate].
  static const splash = '/splash';
  static const authGate = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case AppRoutes.register:
      return MaterialPageRoute(builder: (_) => const RegisterScreen());
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const MainShellScreen());
    case AppRoutes.authGate:
    default:
      return MaterialPageRoute(builder: (_) => const AuthGate());
  }
}
