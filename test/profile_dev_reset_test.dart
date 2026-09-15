import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';

import 'support/pump_app.dart';

/// Covers the development-only fresh-state reset: a debug-only "Reset app
/// state" control on Profile that clears local onboarding/session state so
/// AuthGate's existing routing naturally falls back through the real
/// first-launch flow, without touching the (faked, here) backend.
void main() {
  Future<void> openProfile(WidgetTester tester) async {
    await pumpApp(
      tester,
      overrides: [
        statementFilePickerServiceProvider.overrideWithValue(
          FakeStatementFilePickerService(),
        ),
        chatRepositoryProvider.overrideWithValue(MockChatRepository()),
      ],
    );
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }

  Future<void> openResetDialog(WidgetTester tester) async {
    final resetRow = find.text('Reset app state');
    await tester.dragUntilVisible(
      resetRow,
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(resetRow);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a "Development" section with "Reset app state" is present on Profile',
    (tester) async {
      await openProfile(tester);

      final resetRow = find.text('Reset app state');
      await tester.dragUntilVisible(
        resetRow,
        find.byType(ListView),
        const Offset(0, -300),
      );

      expect(find.text('Development'), findsOneWidget);
      expect(resetRow, findsOneWidget);
    },
  );

  testWidgets('tapping "Reset app state" asks for confirmation first', (
    tester,
  ) async {
    await openProfile(tester);
    await openResetDialog(tester);

    expect(find.text('Reset app state?'), findsOneWidget);
  });

  testWidgets(
    'canceling the confirmation leaves the session and Profile untouched',
    (tester) async {
      await openProfile(tester);
      await openResetDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Still authenticated, still on Profile — the reset never ran.
      expect(find.text('Reset app state?'), findsNothing);
      expect(find.text('Reset app state'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    },
  );

  testWidgets(
    'confirming Reset clears onboarding-seen and auth state, and AuthGate '
    'falls back to the real onboarding flow — not a hardcoded route',
    (tester) async {
      await openProfile(tester);
      await openResetDialog(tester);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      // Flush `hasSeenOnboardingProvider`'s (mocked, async) secure-storage
      // read into a rebuild, same as splash_screen_test/onboarding_screen_test.
      await tester.pump();

      // `pumpApp`'s default seeds "has_seen_onboarding_v1" as already seen —
      // seeing the real onboarding intro here proves the reset actually
      // cleared that persisted flag rather than just navigating somewhere.
      expect(
        find.text('Make sense of your\nmoney with AI.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Welcome back'), findsNothing);
      expect(find.text('Reset app state'), findsNothing);
    },
  );

  testWidgets('after a reset, the fresh-install flow (Onboarding -> Register '
      '-> Chat) works end-to-end without reinstalling', (tester) async {
    await openProfile(tester);
    await openResetDialog(tester);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(
      find.text('Make sense of your\nmoney with AI.', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.pump();
    // A freshly-reset device has never completed a sign-in before, so
    // onboarding leads into account creation, not a screen for an account
    // that doesn't exist yet.
    expect(find.text('Create your \n Account'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);

    await registerNewAccount(tester);
    await tester.pumpAndSettle();

    // `mainTabProvider` (which bottom-nav tab is selected) resets to Chat
    // on every authenticated transition — switch to it explicitly anyway
    // to confirm the real main shell, not just the authenticated gate
    // itself, is reachable.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
  });

  testWidgets(
    'a normal logout (not the dev reset) still returns to Login directly, '
    'without replaying onboarding',
    (tester) async {
      await openProfile(tester);

      final logoutRow = find.text('Log out');
      await tester.dragUntilVisible(
        logoutRow,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(logoutRow);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Log out'),
        ),
      );
      await tester.pumpAndSettle();

      // Straight to Login — the onboarding-seen flag (still true; only the
      // dev reset clears it) means onboarding must not reappear.
      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text('Make sense of your\nmoney with AI.', findRichText: true),
        findsNothing,
      );

      // The real bug this guards against: `pushNamedAndRemoveUntil` leaving
      // a stale Chat/Profile route (or an extra AuthGate instance)
      // underneath the new one. Both the visible affordance and the actual
      // Navigator stack must agree that Login is the root — asserting only
      // the icon's absence would miss a canPop()==true stack with the arrow
      // hidden by some other means.
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Welcome back'))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'Register reached via dev reset -> Onboarding -> Skip is also the '
    'unauthenticated root, with no route left underneath it',
    (tester) async {
      await openProfile(tester);
      await openResetDialog(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.text('Create your \n Account'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(
        Navigator.of(
          tester.element(find.text('Create your \n Account')),
        ).canPop(),
        isFalse,
      );
    },
  );
}
