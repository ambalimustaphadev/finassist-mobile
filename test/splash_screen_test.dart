import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/router.dart';
import 'package:finassist/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';

/// The "Get started" arrow runs an infinite repeating animation once the
/// intro finishes, so `pumpAndSettle()` is unsafe from that point on —
/// advance past the (bounded) intro with an exact-duration `pump()` instead.
///
/// Uses the app's real `onGenerateRoute` (starting at `AppRoutes.splash`),
/// not a bare `MaterialApp(home: SplashScreen())` — `_goToLogin` now
/// navigates via `pushReplacementNamed(AppRoutes.authGate)`, which needs the
/// real named-route table to resolve, and driving it through the actual
/// route table is exactly what proves the navigation-stack fix.
Future<void> _pumpPastIntro(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
      child: MaterialApp(
        initialRoute: AppRoutes.splash,
        onGenerateRoute: onGenerateRoute,
        onGenerateInitialRoutes: (initialRouteName) {
          return [onGenerateRoute(RouteSettings(name: initialRouteName))];
        },
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 2700));
}

void main() {
  for (final size in [
    const Size(375, 667), // small phone (iPhone SE)
    const Size(390, 844), // standard phone (iPhone 14)
    const Size(430, 932), // large phone (iPhone Pro Max)
  ]) {
    testWidgets(
      'Splash mark/name/tagline block is centered on screen at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpPastIntro(tester);

        final blockCenter = tester
            .getRect(find.byKey(const Key('splashCenterBlock')))
            .center;
        expect(blockCenter.dx, closeTo(size.width / 2, 0.5));
        expect(blockCenter.dy, closeTo(size.height / 2, 0.5));
      },
    );
  }

  testWidgets('Get started arrow starts on the left and points right', (
    tester,
  ) async {
    await _pumpPastIntro(tester);

    final arrowIcon = tester.widget<Icon>(
      find.byIcon(Icons.arrow_forward_rounded),
    );
    expect(arrowIcon.icon, Icons.arrow_forward_rounded);

    final buttonCenter = tester.getRect(find.text('Get started')).center.dx;
    final arrowCenter = tester
        .getRect(find.byIcon(Icons.arrow_forward_rounded))
        .center
        .dx;
    expect(arrowCenter, lessThan(buttonCenter));
  });

  testWidgets('Dragging right-to-left does nothing', (tester) async {
    await _pumpPastIntro(tester);

    await tester.drag(find.text('Get started'), const Offset(-200, 0));
    await tester.pump();

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Dragging left-to-right navigates to AuthGate/Login', (
    tester,
  ) async {
    await _pumpPastIntro(tester);

    await tester.drag(find.text('Get started'), const Offset(200, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets(
    'Splash is fully replaced in the nav stack — Login cannot be popped back to it',
    (tester) async {
      await _pumpPastIntro(tester);

      await tester.drag(find.text('Get started'), const Offset(200, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Welcome back'), findsOneWidget);

      // Splash must be gone, not just hidden underneath — canPop is false
      // because Login/AuthGate replaced it rather than being pushed on top.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);

      // A first (and every subsequent) back-swipe/pop attempt must be a
      // no-op: Login stays Login, nothing transitions underneath it.
      for (var i = 0; i < 3; i++) {
        final popped = await navigator.maybePop();
        expect(popped, isFalse);
        await tester.pump();
        expect(find.text('Welcome back'), findsOneWidget);
      }
    },
  );
}
