import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:finassist/features/dashboard/data/repositories/mock_financial_repository.dart';

import 'support/pump_app.dart';

/// Covers the chat header's navigation contract: only the home icon (⌂)
/// returns to Dashboard — the menu only opens the drawer, and "+" only
/// starts a new conversation.
void main() {
  Future<void> openChat(WidgetTester tester) async {
    await pumpApp(
      tester,
      overrides: [
        statementFilePickerServiceProvider.overrideWithValue(
          FakeStatementFilePickerService(),
        ),
        chatRepositoryProvider.overrideWithValue(
          MockChatRepository(MockFinancialRepository()),
        ),
      ],
    );
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    final scrollable = find.byKey(const Key('dashboardScrollView'));
    await tester.drag(scrollable, const Offset(0, -2000));
    await tester.pumpAndSettle();

    final chatCta = find.text('Chat with AI Assistant');
    await tester.ensureVisible(chatCta);
    await tester.pumpAndSettle();
    await tester.tap(chatCta);
    await tester.pump();
    await pumpUntil(tester, find.text('FinAssist AI'));
  }

  Finder headerIcon(IconData icon) {
    return find.descendant(
      of: find.byType(ChatAppBar),
      matching: find.byIcon(icon),
    );
  }

  testWidgets('the home icon is present in the chat header', (tester) async {
    await openChat(tester);

    expect(headerIcon(Icons.home_rounded), findsOneWidget);
  });

  testWidgets(
    'tapping the home icon returns to the existing Dashboard, not a new one',
    (tester) async {
      await openChat(tester);

      // Dashboard is still mounted underneath (Chat was pushed on top of
      // it) — confirm there's exactly one before navigating "back" to it,
      // so we can tell a duplicate wasn't created afterwards.
      expect(find.text('Chat with AI Assistant'), findsOneWidget);

      await tester.tap(headerIcon(Icons.home_rounded));
      await tester.pumpAndSettle();

      expect(find.text('FinAssist AI'), findsNothing);
      expect(find.byKey(const Key('dashboardScrollView')), findsOneWidget);
      // `AuthGate` is the sole root route and renders Dashboard reactively
      // rather than Dashboard ever being pushed as its own route — so
      // popping Chat off leaves exactly one route on the stack, with
      // nothing left below it. A duplicate Dashboard push would instead
      // leave an extra route still poppable here.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    },
  );

  testWidgets(
    'tapping the menu opens the drawer and does not navigate to Dashboard',
    (tester) async {
      await openChat(tester);

      await tester.tap(headerIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('FinAssist AI'), findsOneWidget);
      expect(find.text('New conversation'), findsOneWidget);
      // Still on the chat screen, drawer visible — never navigated home.
      expect(find.byType(ChatAppBar), findsOneWidget);
    },
  );

  testWidgets(
    'tapping "+" starts a new conversation and does not navigate to Dashboard',
    (tester) async {
      await openChat(tester);

      await tester.enterText(
        find.byType(TextField),
        'Can you help me create a budget?',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      // Wait for the assistant's reply to fully arrive (not just the user's
      // echoed message) so the mock repository's simulated-delay timer has
      // already fired before "+" is tapped.
      await pumpUntil(tester, find.textContaining('50/30/20'));

      await tester.tap(headerIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Can you help me create a budget?'), findsNothing);
      expect(find.text('What can I help you with?'), findsOneWidget);
      // Still on the chat screen — never navigated home.
      expect(find.byType(ChatAppBar), findsOneWidget);

      // Drain any straggler mock-response timer so the test doesn't end
      // mid-flight (this is a test-harness cleanliness concern only).
      await tester.pump(const Duration(milliseconds: 2200));
    },
  );
}
