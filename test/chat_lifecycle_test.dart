import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/dashboard/data/repositories/mock_financial_repository.dart';

import 'support/pump_app.dart';

/// Covers the conversation-workspace behaviors that replaced the old
/// single-session "End Chat" flow: starting a new conversation from the
/// header "+", the drawer's recent-conversations list, reopening a
/// previous conversation, and removing an attachment before analysis.
Future<void> _openChat(
  WidgetTester tester, {
  List<Override> extraOverrides = const [],
}) async {
  await pumpApp(
    tester,
    overrides: [
      statementFilePickerServiceProvider.overrideWithValue(
        FakeStatementFilePickerService(),
      ),
      chatRepositoryProvider.overrideWithValue(
        MockChatRepository(MockFinancialRepository()),
      ),
      ...extraOverrides,
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

Future<void> _sendMessage(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
  final sentMessage = find.text(text);
  await pumpUntil(tester, sentMessage);
}

void main() {
  testWidgets('The empty state shows a short, personalized greeting', (
    tester,
  ) async {
    await _openChat(tester);

    // The dashboard route stays mounted underneath and has its own "Good
    // <time of day>" greeting, so match the chat empty state's exact
    // shape ("Good <time>, <name>.") to target only the chat one.
    expect(
      find.textContaining(
        RegExp(r'Good (morning|afternoon|evening), Mustapha\.'),
      ),
      findsOneWidget,
    );
    expect(find.text('What can I help you with?'), findsOneWidget);
    // Never the old long canned paragraph.
    expect(find.textContaining("I'm your financial assistant"), findsNothing);
  });

  testWidgets('"+" starts a new conversation and returns to the empty state', (
    tester,
  ) async {
    await _openChat(tester);

    await _sendMessage(tester, 'Can you help me create a budget?');
    await pumpUntil(tester, find.textContaining('50/30/20'));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Can you help me create a budget?'), findsNothing);
    expect(find.text('What can I help you with?'), findsOneWidget);
  });

  testWidgets(
    'A sent message appears in the drawer as a recent conversation with a real title',
    (tester) async {
      await _openChat(tester);
      await _sendMessage(tester, 'Can you help me create a budget?');
      await pumpUntil(tester, find.textContaining('50/30/20'));

      // Start a fresh thread so the just-sent one shows up under "RECENT".
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('RECENT'), findsOneWidget);
      expect(find.text('Budget planning'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      // No generic placeholder titles.
      expect(find.textContaining('Chat 1'), findsNothing);
      expect(find.textContaining('Conversation 1'), findsNothing);
    },
  );

  testWidgets(
    'Reopening a recent conversation restores its messages, not a new thread',
    (tester) async {
      await _openChat(tester);
      await _sendMessage(tester, 'Can you help me create a budget?');
      await pumpUntil(tester, find.textContaining('50/30/20'));

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('What can I help you with?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budget planning'));
      await tester.pumpAndSettle();

      expect(find.text('Can you help me create a budget?'), findsOneWidget);
      expect(find.text('What can I help you with?'), findsNothing);
    },
  );

  testWidgets(
    'Removing a composer attachment before Send cancels it — never uploaded, '
    'never sent',
    (tester) async {
      await _openChat(tester);

      // Picking a file only ever updates the composer's own local
      // preview — nothing is uploaded or sent to the conversation yet.
      await tester.tap(find.byIcon(Icons.attach_file_rounded));
      await tester.pump();
      final fileCard = find.text('GTBank_Statement.pdf');
      await pumpUntil(tester, fileCard);
      expect(fileCard, findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('GTBank_Statement.pdf'), findsNothing);

      // Nothing was ever uploaded or sent, so there's nothing for an
      // assistant reply to arrive from.
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('finished analyzing'), findsNothing);
    },
  );

  testWidgets(
    'Attaching a file and typing a message sends both together as one turn',
    (tester) async {
      await _openChat(
        tester,
        extraOverrides: [
          fileUploadRepositoryProvider.overrideWithValue(
            FakeFileUploadRepository(),
          ),
        ],
      );

      // Pick a file — only the composer's own preview updates; nothing is
      // uploaded or added to the conversation yet.
      await tester.tap(find.byIcon(Icons.attach_file_rounded));
      await tester.pump();
      await pumpUntil(tester, find.text('GTBank_Statement.pdf'));
      expect(find.text('GTBank_Statement.pdf'), findsOneWidget);
      expect(find.text('What can I help you with?'), findsOneWidget);

      // The user can still type alongside the attached file.
      await tester.enterText(
        find.byType(TextField),
        'Summarize this statement.',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // The composer's own preview is cleared immediately on Send.
      await pumpUntil(tester, find.text('Summarize this statement.'));
      expect(find.text('What can I help you with?'), findsNothing);

      // The message and its file tag now live together in the
      // conversation, and the assistant eventually replies.
      expect(find.text('Summarize this statement.'), findsOneWidget);
      await pumpUntil(
        tester,
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.text('GTBank_Statement.pdf'),
        ),
      );

      // Drain the mock's straggler response timer.
      await tester.pump(const Duration(milliseconds: 2200));
    },
  );

  testWidgets(
    'Deleting a recent conversation from its "..." menu removes it from the drawer',
    (tester) async {
      await _openChat(tester);
      await _sendMessage(tester, 'Can you help me create a budget?');
      await pumpUntil(tester, find.textContaining('50/30/20'));

      // Start a fresh thread so the just-sent one shows up under "RECENT".
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Budget planning'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete conversation?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget planning'), findsNothing);
      // "+ New conversation" and the empty-drawer message still make
      // sense — deleting the only recent conversation doesn't break the
      // rest of the drawer.
      expect(
        find.text('Your recent conversations will show up here.'),
        findsOneWidget,
      );
    },
  );
}
