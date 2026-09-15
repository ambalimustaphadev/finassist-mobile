import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge with transparent system bars so every screen's own
  // Scaffold background paints all the way to the physical edges. Without
  // this, the OS renders its own default (light) status/navigation bar
  // color behind the app content — visible as a mismatched white strip,
  // most obviously against the splash screen's black background. Each
  // screen still controls its own status-bar icon brightness via
  // `AnnotatedRegion<SystemUiOverlayStyle>` (see `SplashScreen`,
  // `AuthScaffold`) since a single global icon color can't suit both a
  // dark screen (Splash) and light ones (Login/Register/main app).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: FinAssistApp()));
}
