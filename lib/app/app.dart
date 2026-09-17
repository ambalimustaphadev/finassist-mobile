import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

class FinAssistApp extends ConsumerWidget {
  const FinAssistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp(
      title: 'FinAssist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: onGenerateRoute,
      // Without this, Navigator's default initial-route generation sees
      // that AppRoutes.splash ('/splash') isn't the root path ('/') and
      // auto-generates an *extra* ancestor route for '/' (which resolves to
      // AuthGate) underneath Splash. That leftover route is invisible until
      // the first back gesture on Login pops through to it — this pins the
      // initial stack to exactly the requested route.
      onGenerateInitialRoutes: (initialRouteName) {
        return [onGenerateRoute(RouteSettings(name: initialRouteName))];
      },
    );
  }
}
