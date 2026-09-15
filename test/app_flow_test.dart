import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';

import 'support/pump_app.dart';

/// Drives the full login -> Chat (FinAssist's landing tab) -> AI
/// conversation flow at both a small and a large phone viewport.
///
/// `pumpAndSettle()` is unsafe once the chat screen is open, since
/// [TypingIndicator] runs a repeating animation that never "settles".
/// Bounded, polling `pump()` calls are used instead.
void main() {
  for (final size in [
    const Size(375, 667), // small phone (iPhone SE)
    const Size(430, 932), // large phone (iPhone Pro Max)
  ]) {
    testWidgets('Full login -> Chat -> AI chat flow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        overrides: [
          statementFilePickerServiceProvider.overrideWithValue(
            FakeStatementFilePickerService(),
          ),
          // The real chatRepositoryProvider points at a live backend —
          // use the mock here so the test doesn't depend on network.
          chatRepositoryProvider.overrideWithValue(MockChatRepository()),
        ],
      );
      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Chat is the landing tab — already on screen after login, no
      // navigation required.
      await pumpUntil(tester, find.text('FinAssist'));
      expect(tester.takeException(), isNull);

      // A short, personalized empty-state greeting — not a long canned
      // paragraph.
      final greeting = find.textContaining(
        RegExp(r'Good (morning|afternoon|evening),\s*\w+\.'),
      );
      await pumpUntil(tester, greeting);
      expect(greeting, findsOneWidget);
      expect(find.text('What would you like to know today?'), findsOneWidget);

      // A plain question gets a plain chat reply — never a fabricated
      // dashboard-style card.
      await tester.enterText(
        find.byType(TextField),
        'Can you help me create a budget?',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      final sentQuestion = find.text('Can you help me create a budget?');
      await pumpUntil(tester, sentQuestion);
      expect(tester.takeException(), isNull);
      expect(sentQuestion, findsOneWidget);

      final reply = find.textContaining('50/30/20');
      await pumpUntil(tester, reply);
      expect(tester.takeException(), isNull);
      expect(reply, findsOneWidget);

      // A quick-action chip goes through the same real AI flow rather
      // than instantly changing state. The chips live in a horizontally
      // scrollable, lazily-built `ListView`, so the third chip isn't
      // even built yet — scroll it into range first.
      await tester.drag(
        find.byKey(const Key('quickActionsList')),
        const Offset(-300, 0),
      );
      await tester.pump();
      final savingsChip = find.text('Find ways to save');
      await tester.ensureVisible(savingsChip);
      await tester.pump();
      await tester.tap(savingsChip);
      await tester.pump();
      final savingsReply = find.textContaining('essential expenses');
      await pumpUntil(tester, savingsReply);
      expect(tester.takeException(), isNull);
      expect(savingsReply, findsWidgets);

      // Drain any straggler mock-response timer so the test doesn't end
      // mid-flight (this is a test-harness cleanliness concern only).
      await tester.pump(const Duration(milliseconds: 2200));
    });
  }
}
