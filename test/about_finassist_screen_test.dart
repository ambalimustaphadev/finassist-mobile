import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets(
    'shows the real product identity, AI transparency and disclaimer copy',
    (tester) async {
      await pumpApp(tester);
      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('About FinAssist'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('About FinAssist'));
      await tester.pumpAndSettle();

      expect(find.text('Your AI financial companion.'), findsOneWidget);
      expect(find.textContaining('Version 1.0.0'), findsWidgets);
      expect(find.text('Ask'), findsOneWidget);
      expect(find.text('Understand'), findsOneWidget);
      expect(find.text('Calculate'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);

      await tester.dragUntilVisible(
        find.textContaining('not a substitute for professional'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(
        find.textContaining('not a substitute for professional'),
        findsOneWidget,
      );
    },
  );
}
