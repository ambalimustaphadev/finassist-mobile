import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/chat/presentation/widgets/chat_app_bar.dart';

import 'support/pump_app.dart';

/// Covers Chat's header navigation contract now that Chat is FinAssist's
/// landing tab: no back arrow, no "go to Dashboard" icon (there's nowhere
/// to go back to), no "+" icon (starting a new chat lives solely in the
/// drawer), the menu opens the drawer without navigating away, and the
/// avatar jumps to the Profile tab.
void main() {
  Future<void> openChat(WidgetTester tester) async {
    await pumpApp(
      tester,
      overrides: [
        statementFilePickerServiceProvider.overrideWithValue(
          FakeStatementFilePickerService(),
        ),
        chatRepositoryProvider.overrideWithValue(MockChatRepository()),
      ],
    );
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();
  }

  Finder headerIcon(IconData icon) {
    return find.descendant(
      of: find.byType(ChatAppBar),
      matching: find.byIcon(icon),
    );
  }

  testWidgets('landing on Chat shows no back arrow and no home icon', (
    tester,
  ) async {
    await openChat(tester);

    expect(headerIcon(Icons.arrow_back_rounded), findsNothing);
    expect(headerIcon(Icons.arrow_back_ios_rounded), findsNothing);
    expect(headerIcon(Icons.home_rounded), findsNothing);
  });

  testWidgets('the header has no "+" icon — new chat lives in the drawer', (
    tester,
  ) async {
    await openChat(tester);

    expect(headerIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets('tapping the menu opens the drawer and does not navigate away', (
    tester,
  ) async {
    await openChat(tester);

    await tester.tap(headerIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsOneWidget);
    // Still on the chat tab, drawer visible — never navigated away.
    expect(find.byType(ChatAppBar), findsOneWidget);
  });

  testWidgets('tapping the avatar switches to the Profile tab', (tester) async {
    await openChat(tester);

    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.byType(ChatAppBar), findsNothing);
  });
}
