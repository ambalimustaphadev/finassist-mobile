import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('Change password from Account is the same honest unavailable '
      'explanation as from Security, not a form that can never submit '
      'anywhere', (tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    expect(find.text("This isn't available yet"), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Save changes'), findsNothing);
  });
}
