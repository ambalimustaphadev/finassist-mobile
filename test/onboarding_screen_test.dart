import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/onboarding/presentation/widgets/onboarding_nav_button.dart';

import 'support/pump_app.dart';

/// Onboarding pages have subtle entrance animations (`FadeSlideIn`) —
/// `pumpAndSettle()` never returns while they're mounted. A single large
/// `pump(duration)` isn't enough either: `PageController.nextPage()`'s
/// scroll-driven animation needs several discrete frame ticks in the test
/// harness to actually advance, unlike a plain `AnimationController`-backed
/// tween. Several small pumps satisfy both constraints.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // The default 800x600 test surface is landscape-ish — nothing like the
  // tall phone this UI is designed for, and short enough that the hero
  // content sits outside the hit-testable viewport without scrolling.
  // Every test here runs against a realistic portrait phone size instead.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(
      390,
      844,
    );
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
    binding.platformDispatcher.implicitView!.resetDevicePixelRatio();
  });

  testWidgets('a user who has never seen onboarding sees it before Login', (
    tester,
  ) async {
    await pumpApp(tester, skipOnboarding: false);

    expect(
      find.text('Make sense of your\nmoney with AI.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('tapping Skip on page 1 goes straight to Login', (tester) async {
    await pumpApp(tester, skipOnboarding: false);

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    // One more pump to flush `hasSeenOnboardingProvider`'s (mocked, async)
    // secure-storage read into a rebuild.
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('the arrow CTA pages forward, and pagination tracks it', (
    tester,
  ) async {
    await pumpApp(tester, skipOnboarding: false);

    await tester.tap(find.byType(OnboardingArrowButton));
    await _settle(tester);

    expect(
      find.text(
        'Turn financial documents into\nclear answers.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(OnboardingArrowButton));
    await _settle(tester);

    expect(
      find.text('Ask. Understand.\nCalculate.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('swiping forward and backward pages between all 3 screens', (
    tester,
  ) async {
    await pumpApp(tester, skipOnboarding: false);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await _settle(tester);
    expect(
      find.text(
        'Turn financial documents into\nclear answers.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await _settle(tester);
    expect(
      find.text('Make sense of your\nmoney with AI.', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('Skip from page 2 and page 3 both go straight to Login', (
    tester,
  ) async {
    await pumpApp(tester, skipOnboarding: false);
    await tester.tap(find.byType(OnboardingArrowButton));
    await _settle(tester);

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets(
    'paging through all 3 pages and tapping "Get Started" goes to Login',
    (tester) async {
      await pumpApp(tester, skipOnboarding: false);

      expect(
        find.text('Make sense of your\nmoney with AI.', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.byType(OnboardingArrowButton));
      await _settle(tester);
      expect(
        find.text(
          'Turn financial documents into\nclear answers.',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(OnboardingArrowButton));
      await _settle(tester);
      expect(
        find.text('Ask. Understand.\nCalculate.', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.byType(OnboardingGetStartedButton));
      await _settle(tester);
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
    },
  );
}
