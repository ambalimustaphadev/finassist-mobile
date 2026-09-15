import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> openSecurity(WidgetTester tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'only shows security functionality that actually exists: password '
    'only, no biometrics/app lock/sessions switches that would do nothing',
    (tester) async {
      await openSecurity(tester);

      expect(find.text('Security'), findsWidgets);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.textContaining('Biometric'), findsNothing);
      expect(find.textContaining('App lock'), findsNothing);
      expect(find.textContaining('Active sessions'), findsNothing);
    },
  );

  testWidgets(
    'tapping "Change password" opens the honest unavailable explanation, '
    'not a fake form that could never actually save',
    (tester) async {
      await openSecurity(tester);

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(find.text("This isn't available yet"), findsOneWidget);
      // No password fields pretending to work.
      expect(find.byType(TextField), findsNothing);
    },
  );
}
