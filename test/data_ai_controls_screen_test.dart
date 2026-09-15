import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> openDataAiControls(WidgetTester tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Data & AI controls'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows the real, persisted Proactive suggestions toggle and no fake '
    'export/training controls',
    (tester) async {
      await openDataAiControls(tester);

      expect(find.text('Proactive suggestions'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.textContaining('Export'), findsNothing);
      expect(find.textContaining("don't use my data"), findsNothing);
    },
  );

  testWidgets(
    'toggling Proactive suggestions persists through the real preferences '
    'API',
    (tester) async {
      await openDataAiControls(tester);

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      // Leaving and coming back proves it actually persisted through the
      // preferences controller, not just local widget state. The Profile
      // list is already scrolled to where this row is from the initial
      // navigation, so no extra scrolling is needed here.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Data & AI controls'));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    },
  );
}
