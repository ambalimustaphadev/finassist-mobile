import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> openHelpFaq(WidgetTester tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Help & FAQ'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help & FAQ'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows categorized questions, collapsed by default', (
    tester,
  ) async {
    await openHelpFaq(tester);

    expect(find.text('Getting started'), findsOneWidget);
    expect(find.text('What is FinAssist?'), findsOneWidget);
    // The answer text isn't shown until expanded.
    expect(
      find.textContaining('helps you make sense of money through'),
      findsNothing,
    );
  });

  testWidgets('tapping a question expands its answer', (tester) async {
    await openHelpFaq(tester);

    await tester.tap(find.text('What is FinAssist?'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('helps you make sense of money through'),
      findsOneWidget,
    );

    // Tapping again collapses it.
    await tester.tap(find.text('What is FinAssist?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('helps you make sense of money through'),
      findsNothing,
    );
  });

  testWidgets('searching filters questions down to matching results', (
    tester,
  ) async {
    await openHelpFaq(tester);

    await tester.enterText(find.byType(TextField), 'password');
    await tester.pumpAndSettle();

    expect(find.text('How do I change my password?'), findsOneWidget);
    expect(find.text('What is FinAssist?'), findsNothing);

    await tester.enterText(find.byType(TextField), 'no such topic exists');
    await tester.pumpAndSettle();
    expect(find.textContaining('No results for'), findsOneWidget);
  });
}
