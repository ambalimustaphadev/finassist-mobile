import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/profile/data/models/profile.dart';

import 'support/pump_app.dart';

/// Covers the new/returning-user routing distinction `AuthGate` makes for
/// an unauthenticated session — `hasCompletedInitialSetupProvider` (set by
/// `AuthController` on every path that reaches `AuthStatus.authenticated`,
/// never cleared by a normal logout) decides Register vs Login, instead of
/// treating "not authenticated" as always meaning "new user".
void main() {
  testWidgets('a fresh/reset device (never signed in) has onboarding lead into '
      'Register, never Login', (tester) async {
    await pumpApp(
      tester,
      skipOnboarding: false,
      hasCompletedInitialSetup: false,
    );

    expect(
      find.text('Make sense of your\nmoney with AI.', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Create your \n Account'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    // Register is the unauthenticated root here, not a pushed screen —
    // no stale back arrow to Onboarding.
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('registering a brand-new account signs the user in immediately, '
      'landing straight in the existing post-signup setup flow with no '
      'second manual Login step', (tester) async {
    final now = DateTime(2026, 1, 1);
    await pumpApp(
      tester,
      profileRepository: FakeProfileRepository(
        initialProfile: Profile(
          id: 2,
          username: 'adalovelace',
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@finassist.com',
          currency: 'NGN',
          onboardingCompleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      ),
    );

    final registerLink = find.text('Register');
    await tester.ensureVisible(registerLink);
    await tester.pumpAndSettle();
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    await registerNewAccount(tester);
    await tester.pumpAndSettle();

    // Straight into the existing (unmodified) post-signup personalization
    // flow — never a second Login screen in between.
    expect(find.text("Let's personalize\nFinAssist for you."), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.byKey(const Key('mainShellScreen')), findsNothing);
  });

  testWidgets(
    'after registering fresh and later logging out, the device is treated '
    'as returning — Login appears next, not Register or Onboarding again',
    (tester) async {
      await pumpApp(tester);

      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.pumpAndSettle();
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      await registerNewAccount(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
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

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Create your \n Account'), findsNothing);
      expect(
        find.text('Make sense of your\nmoney with AI.', findRichText: true),
        findsNothing,
      );
    },
  );

  testWidgets(
    'from a fresh-state Register (the unauthenticated root), "Log in" still '
    'reaches Login, with a working back arrow back to Register',
    (tester) async {
      await pumpApp(tester, hasCompletedInitialSetup: false);
      expect(find.text('Create your \n Account'), findsOneWidget);

      final loginLink = find.text('Log in');
      await tester.ensureVisible(loginLink);
      await tester.pumpAndSettle();
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Create your \n Account'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    },
  );
}
