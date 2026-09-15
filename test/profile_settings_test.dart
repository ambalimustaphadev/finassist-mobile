import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> openLanguageCurrency(WidgetTester tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // The Preferences section (Language & currency) is below the fold.
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language & currency'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selecting a language persists it and shows it in the combined Profile '
    'row subtitle',
    (tester) async {
      await openLanguageCurrency(tester);

      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('French'));
      await tester.pumpAndSettle();

      // One selected check for Language (French) and one for the
      // untouched Currency section (still NGN) — both sections share
      // this one screen now.
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('French · ₦ NGN'), findsOneWidget);
    },
  );

  testWidgets('selecting a currency persists it, updates the combined Profile '
      'subtitle, and feeds the Tools calculators', (tester) async {
    await openLanguageCurrency(tester);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('English · \$ USD'), findsOneWidget);

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    // The 2-column tools grid is taller than the default test
    // viewport, so scroll "Loan Calculator" into view first.
    await tester.dragUntilVisible(
      find.text('Loan Calculator'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Loan Calculator'));
    await tester.pumpAndSettle();

    expect(find.text('Loan amount'), findsOneWidget);
    // The amount field's currency suffix now reflects USD, not Naira.
    expect(find.text('\$'), findsWidgets);
  });
}
