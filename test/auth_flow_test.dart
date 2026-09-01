import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('Back navigation', () {
    testWidgets('Login has no back arrow', (tester) async {
      await pumpApp(tester);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('Register has no back arrow', (tester) async {
      await pumpApp(tester);
      await _goToRegister(tester);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
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

      expect(find.text('Create your account'), findsOneWidget);
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
    'Login with the demo account reaches the dashboard with the right name',
    (tester) async {
      await pumpApp(tester);

      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboardScrollView')), findsOneWidget);
      // The demo account's first name, not a hardcoded one.
      expect(find.textContaining('Mustapha'), findsOneWidget);
    },
  );

  testWidgets(
    'Register screen field order matches the backend contract, and success returns to login',
    (tester) async {
      await pumpApp(tester);
      await _goToRegister(tester);

      final labels = [
        'First name',
        'Last name',
        'Email',
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
      final createAccountButton = find.text('Create account');
      await tester.ensureVisible(createAccountButton);
      await tester.pump();
      await tester.tap(createAccountButton);
      await pumpUntil(tester, find.text('Account created'));
      // Let the sheet's slide-up entrance finish before interacting with
      // it — mid-transition, its contents can sit below the viewport.
      await tester.pumpAndSettle();

      // A polished success sheet, not a generic "registered successfully"
      // message — tapping through it returns to Login.
      expect(find.text('Account created'), findsOneWidget);
      await tester.tap(find.text('Continue to login'));
      await tester.pumpAndSettle();

      // Registration doesn't auto-authenticate — back on Login.
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );
}
