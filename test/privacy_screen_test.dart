import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> openPrivacy(WidgetTester tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'explains real data categories and never claims data is never stored '
    'or never shared',
    (tester) async {
      await openPrivacy(tester);

      expect(find.text('Account information'), findsOneWidget);
      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('Financial documents'), findsOneWidget);
      expect(find.text('AI processing'), findsOneWidget);
      expect(find.textContaining('never shared'), findsNothing);
      expect(find.textContaining('never store'), findsNothing);
    },
  );

  testWidgets(
    'links to Data & AI controls and Manage app permissions actually navigate',
    (tester) async {
      await openPrivacy(tester);

      Future<void> tapLink(String text) async {
        await tester.dragUntilVisible(
          find.text(text),
          find.byType(ListView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
        expect(find.text(text), findsWidgets);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await tapLink('Data & AI controls');
      await tapLink('Manage app permissions');
    },
  );
}
