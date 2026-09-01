import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/dashboard/data/repositories/mock_financial_repository.dart';
import 'package:finassist/features/dashboard/presentation/widgets/app_bottom_nav_bar.dart';

import 'support/pump_app.dart';

/// Covers Profile navigation (from the dashboard avatar and the bottom
/// nav), that it shows the real authenticated user's details rather than
/// anything hardcoded, and that logout actually navigates back to Login.
void main() {
  Future<void> openDashboard(WidgetTester tester) async {
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
  }

  testWidgets(
    'tapping the dashboard avatar opens Profile with the real user\'s details',
    (tester) async {
      await openDashboard(tester);

      await tester.tap(find.byKey(const Key('dashboardProfileAvatar')));
      await tester.pumpAndSettle();

      // The Profile screen's own title, distinct from the bottom nav's
      // "Profile" label — which stays on screen precisely because this is
      // a tab switch, not a full-screen push.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Profile'),
        ),
        findsOneWidget,
      );
      // The demo account's real name/username/email — not the reference
      // design's example ("Mustapha Ambali" / "@mustapha" /
      // "mustapha@email.com" would coincidentally match the first name, but
      // the email must be the account's actual one, not the placeholder).
      expect(find.text('Mustapha Ambali'), findsOneWidget);
      expect(find.text('@mustapha'), findsOneWidget);
      expect(find.text('demo@finassist.com'), findsOneWidget);
      expect(find.text('mustapha@email.com'), findsNothing);
    },
  );

  testWidgets('tapping the "Profile" bottom nav tab opens Profile', (
    tester,
  ) async {
    await openDashboard(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('@mustapha'), findsOneWidget);
  });

  testWidgets(
    'the bottom navigation bar stays visible after switching to Profile',
    (tester) async {
      await openDashboard(tester);

      expect(find.byType(AppBottomNavBar), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Still there — Profile is a tab, not a screen pushed on top that
      // would have carried the bar off screen with it.
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBottomNavBar),
          matching: find.text('Profile'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Appearance" is not present on the Profile page', (
    tester,
  ) async {
    await openDashboard(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsNothing);
  });

  testWidgets('logging out clears the session and returns to Login', (
    tester,
  ) async {
    await openDashboard(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final logoutRow = find.text('Log out');
    await tester.dragUntilVisible(
      logoutRow,
      find.byType(ListView),
      const Offset(0, -300),
    );
    // Profile's viewport is shorter now that it always shares the screen
    // with the bottom nav bar, so let any residual scroll/overscroll
    // physics from the drag above fully settle before tapping — otherwise
    // the tap can land on a position mid-animation.
    await tester.pumpAndSettle();
    await tester.tap(logoutRow);
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Log out'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    // Protected screens are gone from the stack — a back gesture can't
    // reveal them.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });
}
