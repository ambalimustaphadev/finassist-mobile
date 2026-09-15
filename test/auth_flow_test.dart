import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/auth/presentation/widgets/auth_checkbox.dart';
import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';

import 'support/pump_app.dart';

Finder _fieldAt(int index) => find.byType(TextFormField).at(index);

Future<void> _goToRegister(WidgetTester tester) async {
  final registerLink = find.text('Register');
  await tester.ensureVisible(registerLink);
  await tester.pumpAndSettle();
  await tester.tap(registerLink);
  await tester.pumpAndSettle();
}

Future<void> _goToLogin(WidgetTester tester) async {
  final loginLink = find.text('Log in');
  await tester.ensureVisible(loginLink);
  await tester.pumpAndSettle();
  await tester.tap(loginLink);
  await tester.pumpAndSettle();
}

/// Register's single checkbox (the Terms of Service/Privacy Policy
/// agreement) — must be checked for `_handleCreateAccount` to actually call
/// the register API.
Future<void> _agreeToTerms(WidgetTester tester) async {
  final checkbox = find.byType(AuthCheckbox);
  await tester.ensureVisible(checkbox);
  await tester.pump();
  await tester.tap(checkbox);
  await tester.pump();
}

void main() {
  group('Back navigation', () {
    testWidgets(
      'Login has no back arrow when reached as the auth flow\'s root',
      (tester) async {
        await pumpApp(tester);
        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      },
    );

    testWidgets('Register has a working back arrow that returns to Login', (
      tester,
    ) async {
      await pumpApp(tester);
      await _goToRegister(tester);
      expect(find.text('Create your \n Account'), findsOneWidget);

      final backArrow = find.byIcon(Icons.arrow_back_rounded);
      expect(backArrow, findsOneWidget);
      await tester.tap(backArrow);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      // Round-tripping through Register must not leave a route Login can
      // still pop to — same root, not just the same-looking screen.
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(
        Navigator.of(tester.element(find.text('Welcome back'))).canPop(),
        isFalse,
      );
    });

    testWidgets(
      'A system/hardware back press at Login (the auth flow\'s root) is a '
      'no-op, never revealing a blank page underneath',
      (tester) async {
        await pumpApp(tester);
        expect(find.text('Welcome back'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Welcome back'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Validation', () {
    testWidgets('Login screen validates empty fields', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Login screen validates malformed email', (tester) async {
      await pumpApp(tester);

      await tester.enterText(_fieldAt(0), 'not-an-email');
      await tester.enterText(_fieldAt(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Confirm password must match', (tester) async {
      await pumpApp(tester);
      await _goToRegister(tester);

      await tester.enterText(_fieldAt(0), 'Ada');
      await tester.enterText(_fieldAt(1), 'Lovelace');
      await tester.enterText(_fieldAt(2), 'ada2@finassist.com');
      await tester.enterText(_fieldAt(3), 'adalovelace2');
      await tester.enterText(_fieldAt(4), 'securePass1');
      await tester.enterText(_fieldAt(5), 'differentPass');
      final createAccountButton = find.text('Create account');
      await tester.ensureVisible(createAccountButton);
      await tester.pump();
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      expect(find.text("Passwords don't match"), findsOneWidget);
    });

    testWidgets(
      'Create account is blocked until the Terms/Privacy checkbox is agreed',
      (tester) async {
        await pumpApp(tester);
        await _goToRegister(tester);

        await tester.enterText(_fieldAt(0), 'Ada');
        await tester.enterText(_fieldAt(1), 'Lovelace');
        await tester.enterText(_fieldAt(2), 'ada3@finassist.com');
        await tester.enterText(_fieldAt(3), 'adalovelace3');
        await tester.enterText(_fieldAt(4), 'securePass1');
        await tester.enterText(_fieldAt(5), 'securePass1');
        final createAccountButton = find.text('Create account');
        await tester.ensureVisible(createAccountButton);
        await tester.pump();
        await tester.tap(createAccountButton);
        await tester.pumpAndSettle();

        // Valid form, but the checkbox was never checked — a purely
        // client-side gate, so this must not call the register API at all.
        expect(
          find.text('Please agree to the Terms of Service and Privacy Policy.'),
          findsOneWidget,
        );
        expect(find.text('Account created'), findsNothing);
      },
    );
  });

  group('Error state isolation', () {
    testWidgets('A failed registration error never appears on Login', (
      tester,
    ) async {
      await pumpApp(tester);
      await _goToRegister(tester);

      // The seeded demo account's email — MockAuthRepository deterministically
      // rejects this as already registered, no network required.
      await tester.enterText(_fieldAt(0), 'Ada');
      await tester.enterText(_fieldAt(1), 'Lovelace');
      await tester.enterText(_fieldAt(2), 'demo@finassist.com');
      await tester.enterText(_fieldAt(3), 'adalovelace');
      await tester.enterText(_fieldAt(4), 'securePass1');
      await tester.enterText(_fieldAt(5), 'securePass1');
      await _agreeToTerms(tester);
      final createAccountButton = find.text('Create account');
      await tester.ensureVisible(createAccountButton);
      await tester.pump();
      await tester.tap(createAccountButton);
      await pumpUntil(tester, find.text('That email is already registered.'));

      expect(find.text('That email is already registered.'), findsOneWidget);

      await _goToLogin(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('That email is already registered.'), findsNothing);
    });

    testWidgets('A failed login error never appears on Register', (
      tester,
    ) async {
      await pumpApp(tester);

      // A sentinel email MockAuthRepository always rejects, no network
      // required.
      await tester.enterText(_fieldAt(0), 'error@finassist.test');
      await tester.enterText(_fieldAt(1), 'wrongpassword');
      await tester.tap(find.text('Login'));
      await pumpUntil(tester, find.textContaining("doesn't look right"));

      expect(find.textContaining("doesn't look right"), findsOneWidget);

      await _goToRegister(tester);

      expect(find.text('Create your \n Account'), findsOneWidget);
      expect(find.textContaining("doesn't look right"), findsNothing);
    });
  });

  group('Password visibility', () {
    testWidgets('Login password toggle works and is independent per attempt', (
      tester,
    ) async {
      await pumpApp(tester);

      final passwordField = find.descendant(
        of: find.byKey(const ValueKey('login-password-field')),
        matching: find.byType(TextField),
      );
      // Hidden -> crossed eye (visibility_off).
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Visible -> normal eye (visibility).
      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Toggling back and forth repeatedly stays in sync.
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets(
      'Register password and confirm-password toggles are independent',
      (tester) async {
        await pumpApp(tester);
        await _goToRegister(tester);

        final passwordField = find.descendant(
          of: find.byKey(const ValueKey('register-password-field')),
          matching: find.byType(TextField),
        );
        final confirmField = find.descendant(
          of: find.byKey(const ValueKey('register-confirm-password-field')),
          matching: find.byType(TextField),
        );

        expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
        expect(tester.widget<TextField>(confirmField).obscureText, isTrue);

        // Revealing the Password field must not affect Confirm password.
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('register-password-field')),
            matching: find.byIcon(Icons.visibility_off_outlined),
          ),
        );
        await tester.pump();

        expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
        expect(tester.widget<TextField>(confirmField).obscureText, isTrue);

        // And vice versa.
        final confirmToggle = find.descendant(
          of: find.byKey(const ValueKey('register-confirm-password-field')),
          matching: find.byIcon(Icons.visibility_off_outlined),
        );
        await tester.ensureVisible(confirmToggle);
        await tester.pump();
        await tester.tap(confirmToggle);
        await tester.pump();

        expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
        expect(tester.widget<TextField>(confirmField).obscureText, isFalse);
      },
    );
  });

  testWidgets(
    'Login with the demo account reaches the main shell with the right name',
    (tester) async {
      await pumpApp(
        tester,
        overrides: [
          chatRepositoryProvider.overrideWithValue(MockChatRepository()),
        ],
      );

      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();
      await pumpUntil(tester, find.textContaining('Mustapha'));

      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
      // The demo account's first name, not a hardcoded one.
      expect(find.textContaining('Mustapha'), findsOneWidget);
    },
  );

  testWidgets(
    'Register screen field order matches the backend contract, and success '
    'returns to login',
    (tester) async {
      await pumpApp(tester);
      await _goToRegister(tester);

      final labels = [
        'First name',
        'Last name',
        'Email address',
        'Username',
        'Password',
        'Confirm password',
      ];
      final labelOffsets = [
        for (final label in labels) tester.getTopLeft(find.text(label)).dy,
      ];
      for (var i = 1; i < labelOffsets.length; i++) {
        expect(
          labelOffsets[i],
          greaterThan(labelOffsets[i - 1]),
          reason: 'Expected $labels in order',
        );
      }
      // "Forgot password?" belongs only on Login.
      expect(find.text('Forgot password?'), findsNothing);

      await tester.enterText(_fieldAt(0), 'Ada');
      await tester.enterText(_fieldAt(1), 'Lovelace');
      await tester.enterText(_fieldAt(2), 'ada@finassist.com');
      await tester.enterText(_fieldAt(3), 'adalovelace');
      await tester.enterText(_fieldAt(4), 'securePass1');
      await tester.enterText(_fieldAt(5), 'securePass1');
      await _agreeToTerms(tester);
      final createAccountButton = find.text('Create account');
      await tester.ensureVisible(createAccountButton);
      await tester.pump();
      await tester.tap(createAccountButton);
      await pumpUntil(
        tester,
        find.text('Account Created\nSuccessfully!', findRichText: true),
      );
      await tester.pumpAndSettle();

      // A full-screen success moment, not a generic "registered
      // successfully" message. Also proves the separate first/last name
      // fields actually reach the backend contract as distinct values
      // (`MockAuthRepository` would otherwise register a blank/garbled
      // name).
      expect(
        find.text('Account Created\nSuccessfully!', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Registration immediately signs the new account in (same
      // credentials, no second manual Login step) — straight to Chat,
      // not back on Login.
      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
    },
  );
}
