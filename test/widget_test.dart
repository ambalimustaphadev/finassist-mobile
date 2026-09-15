import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> pumpAndLogin(WidgetTester tester) async {
    await pumpApp(
      tester,
      overrides: [
        chatRepositoryProvider.overrideWithValue(MockChatRepository()),
      ],
    );
    expect(find.text('Welcome back'), findsOneWidget);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('Login lands directly on Chat — no dashboard step in between', (
    tester,
  ) async {
    await pumpAndLogin(tester);
    await pumpUntil(tester, find.text('What would you like to know today?'));

    // The greeting is time-of-day dependent, so match any of the three.
    expect(
      find.textContaining(RegExp(r'Good (morning|afternoon|evening)')),
      findsOneWidget,
    );
    expect(find.text('What would you like to know today?'), findsOneWidget);
  });

  testWidgets('Chat is reachable immediately — no CTA tap needed', (
    tester,
  ) async {
    await pumpAndLogin(tester);
    await pumpUntil(tester, find.text('Ask FinAssist anything...'));

    expect(find.text('FinAssist'), findsWidgets);
    expect(find.text('Ask FinAssist anything...'), findsOneWidget);
  });
}
