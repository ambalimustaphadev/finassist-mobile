import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('Login then dashboard loads with greeting and chat CTA', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    // The greeting is time-of-day dependent, so match any of the three.
    expect(
      find.textContaining(RegExp(r'Good (morning|afternoon|evening)')),
      findsOneWidget,
    );

    final chatCta = find.text('Chat with AI Assistant');
    await tester.dragUntilVisible(
      chatCta,
      find.byKey(const Key('dashboardScrollView')),
      const Offset(0, -300),
    );
    expect(chatCta, findsOneWidget);
  });

  testWidgets('Tapping the chat CTA navigates to the AI chat screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    final chatCta = find.text('Chat with AI Assistant');
    await tester.dragUntilVisible(
      chatCta,
      find.byKey(const Key('dashboardScrollView')),
      const Offset(0, -300),
    );
    await tester.tap(chatCta);
    await tester.pumpAndSettle();

    expect(find.text('FinAssist AI'), findsOneWidget);
  });
}
