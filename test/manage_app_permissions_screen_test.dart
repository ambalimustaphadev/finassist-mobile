import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('shows only permissions FinAssist actually requests: Camera and '
      'Notifications, never Photos', (tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage app permissions'));
    await tester.pumpAndSettle();
    // permission_handler's plugin channel isn't mocked in a widget test
    // environment — let the screen's own error handling settle to its
    // safe fallback state instead of leaving a pending timer.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Photos'), findsNothing);
  });
}
