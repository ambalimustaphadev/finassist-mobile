import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/chat/presentation/widgets/file_attachment_card.dart';
import 'package:finassist/shared/widgets/document_viewer_screen.dart';

import 'support/pump_app.dart';

/// Covers the conversation-workspace behaviors on Chat, FinAssist's
/// landing tab: the empty state, starting a new conversation from the
/// drawer's "+ New chat" (the only way to do it now — there is no header
/// "+" anymore), the recent-conversations list, reopening a previous
/// conversation, and removing an attachment before analysis.
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
      chatRepositoryProvider.overrideWithValue(MockChatRepository()),
      ...extraOverrides,
    ],
  );
  // Chat is the landing tab — no CTA tap or navigation needed to reach it.
  await loginWithDemoAccount(tester);
  await tester.pumpAndSettle();
  await pumpUntil(tester, find.text('What would you like to know today?'));
}

Future<void> _sendMessage(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
  final sentMessage = find.text(text);
  await pumpUntil(tester, sentMessage);
}

/// Opens the drawer and taps "New chat" — the sole entry point for
/// starting a fresh conversation now that the header has no "+" icon.
Future<void> _startNewChatFromDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text('New chat'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('The empty state shows a short, personalized greeting', (
    tester,
  ) async {
    await _openChat(tester);

    expect(
      find.textContaining(
        RegExp(r'Good (morning|afternoon|evening),\s*Mustapha\.'),
      ),
      findsOneWidget,
    );
    expect(find.text('What would you like to know today?'), findsOneWidget);
    // Never the old long canned paragraph.
    expect(find.textContaining("I'm your financial assistant"), findsNothing);
  });

  testWidgets(
    '"New chat" from the drawer starts a new conversation and returns to '
    'the empty state',
    (tester) async {
      await _openChat(tester);

      await _sendMessage(tester, 'Can you help me create a budget?');
      await pumpUntil(tester, find.textContaining('50/30/20'));

      await _startNewChatFromDrawer(tester);

      expect(find.text('Can you help me create a budget?'), findsNothing);
      expect(find.text('What would you like to know today?'), findsOneWidget);
    },
  );

  testWidgets(
    'A sent message appears in the drawer as a recent conversation with a real title',
    (tester) async {
      await _openChat(tester);
      await _sendMessage(tester, 'Can you help me create a budget?');
      await pumpUntil(tester, find.textContaining('50/30/20'));

      // Start a fresh thread so the just-sent one shows up under "Recent".
      await _startNewChatFromDrawer(tester);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Recent'), findsOneWidget);
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

      await _startNewChatFromDrawer(tester);
      expect(find.text('What would you like to know today?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budget planning'));
      await tester.pumpAndSettle();

      expect(find.text('Can you help me create a budget?'), findsOneWidget);
      expect(find.text('What would you like to know today?'), findsNothing);
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
      expect(find.text('What would you like to know today?'), findsOneWidget);

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
      expect(find.text('What would you like to know today?'), findsNothing);

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
    'Send is disabled with empty text and no attachment — tapping it does '
    'nothing',
    (tester) async {
      await _openChat(tester);

      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(find.text('What would you like to know today?'), findsOneWidget);
    },
  );

  testWidgets(
    'Attaching a file with no typed text alone enables Send and delivers a '
    'file-only message — never an invented instruction like "Analyze this '
    'document."',
    (tester) async {
      await _openChat(
        tester,
        extraOverrides: [
          fileUploadRepositoryProvider.overrideWithValue(
            FakeFileUploadRepository(),
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.attach_file_rounded));
      await tester.pump();
      await pumpUntil(tester, find.text('GTBank_Statement.pdf'));
      expect(find.text('GTBank_Statement.pdf'), findsOneWidget);
      expect(find.text('What would you like to know today?'), findsOneWidget);

      // No text typed at all — Send must still be tappable purely because
      // a file is attached.
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      await pumpUntil(
        tester,
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.text('GTBank_Statement.pdf'),
        ),
      );

      expect(find.text('What would you like to know today?'), findsNothing);
      // No fabricated user text anywhere in the conversation.
      expect(find.textContaining('Analyze this document'), findsNothing);

      // Drain the mock's straggler response timer.
      await tester.pump(const Duration(milliseconds: 2200));
    },
  );

  testWidgets(
    'A sent attachment opens the in-app document viewer, and reopening the '
    'conversation later still shows it — a document belongs to its '
    'conversation, not a separate Documents page',
    (tester) async {
      await _openChat(
        tester,
        extraOverrides: [
          fileUploadRepositoryProvider.overrideWithValue(
            FakeFileUploadRepository(),
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.attach_file_rounded));
      await tester.pump();
      await pumpUntil(tester, find.text('GTBank_Statement.pdf'));
      await tester.enterText(
        find.byType(TextField),
        'Summarize this statement.',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await pumpUntil(
        tester,
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.text('GTBank_Statement.pdf'),
        ),
      );
      // Drain the mock's straggler response timer so it doesn't fire
      // after the conversation below has moved on.
      await tester.pump(const Duration(milliseconds: 2200));

      // Tapping the attachment inside the conversation opens the shared
      // in-app viewer — never a separate Documents screen (which no
      // longer exists). Deliberately bounded `pump()` calls, not
      // `pumpAndSettle()`, once the viewer is on screen: its PDF fetch
      // never resolves against a real network in this test, and its
      // loading spinner animates forever. A freshly-pushed route's
      // content is offstage for its very first frame (`find.byType`
      // skips offstage widgets by default), so this always pumps once
      // more with a small duration before asserting the viewer appeared.
      Future<void> openAttachment() async {
        await tester.ensureVisible(find.byType(FileAttachmentCard).first);
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .descendant(
                of: find.byType(FileAttachmentCard),
                matching: find.byType(InkWell),
              )
              .first,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await openAttachment();
      expect(find.byType(DocumentViewerScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DocumentViewerScreen), findsNothing);

      // Start a new thread, then reopen the one with the attachment —
      // its document reference must still be there and still tappable.
      await _startNewChatFromDrawer(tester);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      // The mock gives statement-related conversations a nicer canned
      // title ("Statement review") rather than echoing the raw message.
      await tester.tap(find.text('Statement review'));
      await tester.pumpAndSettle();

      // The reopened conversation restores the attachment from its stored
      // file_id alone (no original filename is persisted for a restored
      // message, same as the real backend contract — see
      // `ApiChatRepository._parseContent`), so it won't necessarily be
      // "GTBank_Statement.pdf" again, just still a real, tappable
      // reference.
      expect(find.byType(FileAttachmentCard), findsOneWidget);
      await openAttachment();
      expect(find.byType(DocumentViewerScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Deleting a recent conversation from its "..." menu removes it from the drawer',
    (tester) async {
      await _openChat(tester);
      await _sendMessage(tester, 'Can you help me create a budget?');
      await pumpUntil(tester, find.textContaining('50/30/20'));

      // Start a fresh thread so the just-sent one shows up under "Recent".
      await _startNewChatFromDrawer(tester);

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
      // "New chat" and the empty-drawer message still make sense —
      // deleting the only recent conversation doesn't break the rest of
      // the drawer.
      expect(
        find.text('Your recent conversations will show up here.'),
        findsOneWidget,
      );
    },
  );
}
