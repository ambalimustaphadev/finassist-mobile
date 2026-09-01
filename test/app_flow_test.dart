import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/dashboard/data/repositories/mock_financial_repository.dart';

import 'support/pump_app.dart';

/// Drives the full login → dashboard → chat flow, including the
/// upload-gated AI conversation, at both a small and a large phone
/// viewport.
///
/// `pumpAndSettle()` is unsafe once the chat screen is open, since
/// [TypingIndicator] runs a repeating animation that never "settles".
/// Bounded, polling `pump()` calls are used instead.
///
/// The chat viewport deliberately doesn't auto-scroll to follow a growing
/// response (see `ChatScreen._handleChatStateChange`) — a new turn is
/// anchored near the top and content beyond the fold needs a manual
/// scroll, same as a real user would do. [_waitVisible] mirrors that: it
/// polls and, if the target still isn't built, nudges the list down
/// before polling again.
Future<void> _waitVisible(
  WidgetTester tester,
  Finder finder, {
  int maxTries = 60,
}) async {
  final listView = find.byType(ListView);
  for (var i = 0; i < maxTries; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 150));
    if (finder.evaluate().isEmpty && listView.evaluate().isNotEmpty) {
      await tester.drag(listView.first, const Offset(0, -400));
      await tester.pump();
    }
  }
}

void main() {
  for (final size in [
    const Size(375, 667), // small phone (iPhone SE)
    const Size(430, 932), // large phone (iPhone Pro Max)
  ]) {
    testWidgets('Full login -> dashboard -> gated AI chat flow at $size', (
      tester,
    ) async {
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
          chatRepositoryProvider.overrideWithValue(
            MockChatRepository(MockFinancialRepository()),
          ),
        ],
      );
      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Scroll the dashboard to force every card to build and lay out.
      final scrollable = find.byKey(const Key('dashboardScrollView'));
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final chatCta = find.text('Chat with AI Assistant');
      await tester.ensureVisible(chatCta);
      await tester.pumpAndSettle();
      await tester.tap(chatCta);
      await tester.pump();
      await pumpUntil(tester, find.text('FinAssist AI'));
      expect(tester.takeException(), isNull);
      expect(find.text('FinAssist AI'), findsOneWidget);

      // A short, personalized empty-state greeting — not a long canned
      // paragraph — and no financial data yet, so no statement context bar.
      //
      // The dashboard route stays mounted underneath (Navigator keeps
      // pushed routes alive), and its own greeting also contains "Good
      // <time of day>", so match the chat empty state's exact
      // "Good <time>, <name>." shape (comma before the name, period after)
      // to disambiguate from the dashboard's "Good <time>,\n<name> 👋".
      final greeting = find.textContaining(
        RegExp(r'Good (morning|afternoon|evening), \w+\.'),
      );
      await pumpUntil(tester, greeting);
      expect(greeting, findsOneWidget);
      expect(find.text('What can I help you with?'), findsOneWidget);
      // No statement context bar yet — nothing has been analyzed.
      expect(find.text('View summary'), findsNothing);

      // Ask a transaction-specific question before any statement exists:
      // the assistant must NOT fabricate an answer, only offer to analyze
      // one once uploaded.
      await tester.enterText(
        find.byType(TextField),
        'Where am I spending the most?',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      final sentQuestion = find.text('Where am I spending the most?');
      await pumpUntil(tester, sentQuestion);
      expect(tester.takeException(), isNull);
      expect(sentQuestion, findsOneWidget);

      final uploadButton = find.text('Upload Statement');
      await pumpUntil(tester, uploadButton);
      expect(tester.takeException(), isNull);
      expect(uploadButton, findsOneWidget);
      // It must not have jumped straight to a real breakdown.
      expect(find.text('Food & Dining'), findsNothing);

      // Tap "Upload Statement" -> file picker (faked) -> file card in chat
      // -> longer analysis delay -> mock analysis result.
      await tester.ensureVisible(uploadButton);
      await tester.pump();
      await tester.tap(uploadButton);
      await tester.pump();
      final fileCard = find.text('GTBank_Statement.pdf');
      await pumpUntil(tester, fileCard);
      expect(tester.takeException(), isNull);
      expect(fileCard, findsOneWidget);

      final analysisResult = find.textContaining('finished analyzing');
      await _waitVisible(tester, analysisResult); // up to ~4s mock delay
      expect(tester.takeException(), isNull);
      expect(analysisResult, findsOneWidget);
      // The uploaded file's context now backs the conversation. Checked
      // via state rather than a text finder: by this point the list has
      // been scrolled well past the newest message, and the statement
      // context bar (the list's first item) and the original
      // file-attachment bubble are both legitimately scrolled far enough
      // out of view that ListView's normal viewport virtualization no
      // longer builds them — not a rendering bug, just not what this
      // assertion should depend on.
      final chatState = ProviderScope.containerOf(
        tester.element(find.text('FinAssist AI')),
        listen: false,
      ).read(chatControllerProvider);
      expect(chatState.hasFinancialData, isTrue);
      expect(chatState.statementFileName, 'GTBank_Statement.pdf');

      // Now that a statement has been analyzed, the same kind of question
      // should get a real, data-backed answer.
      await tester.enterText(
        find.byType(TextField),
        'Can you show me my recurring payments?',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      // "Recurring payments" alone is ambiguous — it's also a quick-action
      // chip label that's already on screen — so match the response text.
      final recurringReply = find.textContaining('recurring payments totaling');
      await _waitVisible(tester, recurringReply);
      expect(tester.takeException(), isNull);
      expect(recurringReply, findsOneWidget);

      // Quick action chip (the first one, always on-screen) still goes
      // through the same AI flow rather than instantly changing state.
      await tester.tap(find.text('Spending summary'));
      await tester.pump();
      final summaryReply = find.textContaining('spent the most on');
      await _waitVisible(tester, summaryReply);
      expect(tester.takeException(), isNull);
      expect(summaryReply, findsWidgets);

      // Drain any straggler mock-response timer so the test doesn't end
      // mid-flight (this is a test-harness cleanliness concern only).
      await tester.pump(const Duration(milliseconds: 2200));
    });
  }
}
