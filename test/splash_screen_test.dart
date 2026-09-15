import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/router.dart';
import 'package:finassist/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';
import 'package:finassist/features/splash/presentation/splash_timeline.dart';

/// `AuthGate`'s unauthenticated branch checks `hasSeenOnboardingProvider`
/// and `hasCompletedInitialSetupProvider` (both secure-storage-backed)
/// before showing Login — left unmocked, those reads never resolve, so
/// `_AuthGateLoading`'s spinner would stay up forever and Login would never
/// appear. Both pre-seeded "already done" since this suite is about the
/// splash's own animation and hand-off, not onboarding or new-vs-returning
/// routing.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  final values = <String, String>{
    'has_seen_onboarding_v1': 'true',
    'has_completed_initial_setup_v1': 'true',
  };
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return values[call.arguments['key']];
        case 'write':
          values[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        default:
          return null;
      }
    },
  );
}

/// Uses the app's real `onGenerateRoute` (starting at `AppRoutes.splash`),
/// not a bare `MaterialApp(home: SplashScreen())` — navigation happens via
/// `pushReplacementNamed(AppRoutes.authGate)`, which needs the real
/// named-route table to resolve.
Future<void> _pumpSplash(WidgetTester tester) async {
  _mockSecureStorage(TestWidgetsFlutterBinding.ensureInitialized());
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
}

void main() {
  testWidgets(
    'the splash is one continuous animation with no Get Started/Skip/Next '
    'controls, page dots or swipe affordance',
    (tester) async {
      await _pumpSplash(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Get started'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(find.byType(PageView), findsNothing);
    },
  );

  testWidgets('a swipe gesture does nothing — this is not a swipeable intro', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.dragFrom(const Offset(20, 300), const Offset(320, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets(
    'the FinAssist wordmark and tagline appear mid-sequence',
    (tester) async {
      await _pumpSplash(tester);
      // Well inside the wordmark/tagline window, well before completion.
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.textContaining('Assist'), findsWidgets);
      expect(find.text('Smarter Finances.\nA Brighter You.'), findsOneWidget);
    },
  );

  testWidgets('the four feature cards all appear before the sequence ends', (
    tester,
  ) async {
    await _pumpSplash(tester);
    // Well inside the cards' entrance window, well before completion.
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Track'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Achieve'), findsOneWidget);
  });

  testWidgets('the bottom status caption appears during the sequence', (
    tester,
  ) async {
    await _pumpSplash(tester);
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('BUILDING A BRIGHTER TOMORROW'), findsOneWidget);
  });

  testWidgets(
    'the sequence completes and hands off to AuthGate/Login automatically, '
    'without any user interaction',
    (tester) async {
      await _pumpSplash(tester);

      // A plain `Future.delayed` (the completion hold) doesn't itself
      // schedule a frame, so `pumpAndSettle` can settle before it fires.
      // Two separate pumps (not one combined one) so that delayed future,
      // scheduled only once the controller finishes partway through the
      // first pump, gets its own chance to fire — then `pumpAndSettle`
      // finishes the page-transition animation `pushReplacementNamed`
      // starts fresh once the hold elapses.
      await tester.pump(
        SplashTimeline.totalDuration + const Duration(milliseconds: 50),
      );
      await tester.pump(
        SplashTimeline.completionHold + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      // One more pump to flush `hasSeenOnboardingProvider`'s (mocked,
      // async) secure-storage read into a rebuild.
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
    },
  );

  testWidgets(
    'Splash is fully replaced in the nav stack — Login cannot be popped '
    'back to it',
    (tester) async {
      await _pumpSplash(tester);
      // Two separate pumps (not one combined one) so the completion-hold
      // `Future.delayed`, scheduled only once the controller finishes
      // partway through the first pump, gets its own chance to fire.
      await tester.pump(
        SplashTimeline.totalDuration + const Duration(milliseconds: 50),
      );
      await tester.pump(
        SplashTimeline.completionHold + const Duration(milliseconds: 50),
      );
      await tester.pumpAndSettle();
      // One more pump to flush `hasSeenOnboardingProvider`'s (mocked,
      // async) secure-storage read into a rebuild.
      await tester.pump();
      expect(find.text('Welcome back'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);

      for (var i = 0; i < 3; i++) {
        final popped = await navigator.maybePop();
        expect(popped, isFalse);
        await tester.pump();
        expect(find.text('Welcome back'), findsOneWidget);
      }
    },
  );

  for (final size in [
    const Size(375, 667), // small phone (iPhone SE)
    const Size(390, 844), // standard phone (iPhone 14)
    const Size(430, 932), // large phone (iPhone Pro Max)
  ]) {
    testWidgets('renders without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpSplash(tester);
      // Pump across the whole timeline in steps, stopping just short of
      // completion so the post-completion navigation timer never fires
      // mid-test — an overflow or layout exception in any frame up to
      // that point still fails the test.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the total sequence stays within the 2.2–2.8s target budget', (
    tester,
  ) async {
    final total = SplashTimeline.totalDuration + SplashTimeline.completionHold;
    expect(total, greaterThanOrEqualTo(const Duration(milliseconds: 2200)));
    expect(total, lessThanOrEqualTo(const Duration(milliseconds: 2800)));
  });
}
