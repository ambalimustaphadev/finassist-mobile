import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/shell/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:finassist/features/shell/presentation/widgets/main_header_bar.dart';
import 'package:finassist/features/shell/presentation/widgets/quick_chat_fab.dart';

import 'support/pump_app.dart';

/// Covers the main shell's bottom navigation contract: Chat, Track, Tools,
/// Profile — in that order, with no Quick tab — and the quick-chat
/// floating shortcut that shows on every non-Chat tab.
void main() {
  Future<void> openApp(WidgetTester tester) async {
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

  testWidgets('bottom nav shows Chat, Track, Tools, Profile in order — no Quick', (
    tester,
  ) async {
    await openApp(tester);

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(AppBottomNavBar),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .toList();

    expect(labels, ['Chat', 'Track', 'Tools', 'Profile']);
  });

  testWidgets('the quick-chat FAB is absent on Chat and present elsewhere, and returns to Chat', (
    tester,
  ) async {
    await openApp(tester);

    // Lands on Chat by default — no FAB.
    expect(find.byType(QuickChatFab), findsNothing);

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickChatFab), findsOneWidget);

    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickChatFab), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickChatFab), findsOneWidget);

    await tester.tap(find.byType(QuickChatFab));
    await tester.pumpAndSettle();

    expect(find.byType(QuickChatFab), findsNothing);
  });

  testWidgets('Track opens the existing Subscription Tracker directly', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.text('Track'));
    await tester.pumpAndSettle();

    expect(find.text('Subscriptions'), findsOneWidget);
  });

  testWidgets(
    'Track is presented as a root tab — shared MainHeaderBar, no back '
    'arrow, and its menu opens the same drawer as Tools',
    (tester) async {
      await openApp(tester);

      // Tools, for comparison: has the shared header, no back arrow.
      await tester.tap(find.text('Tools'));
      await tester.pumpAndSettle();
      expect(find.byType(MainHeaderBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      // Track should look the same way, not like a pushed detail screen.
      await tester.tap(find.text('Track'));
      await tester.pumpAndSettle();
      expect(find.byType(MainHeaderBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(find.text('New chat'), findsOneWidget);
    },
  );

  testWidgets('Tools no longer contains a Subscription Tracker entry', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();

    expect(find.text('Subscription Tracker'), findsNothing);
    expect(find.text('Calculate'), findsOneWidget);
  });
}
