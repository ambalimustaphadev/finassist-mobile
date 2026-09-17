import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/profile/data/models/profile.dart';
import 'package:finassist/features/profile/data/repositories/profile_repository.dart';
import 'package:finassist/features/shell/presentation/widgets/app_bottom_nav_bar.dart';

import 'support/pump_app.dart';

/// `/api/profile` and its one automatic retry (see `ProfileController._load`)
/// both fail on every call — simulates the API being down for the whole
/// time Profile is on screen, with no picture upload or other mutation
/// ever giving `state.profile` a chance to get populated another way.
class _AlwaysFailingProfileRepository implements ProfileRepository {
  @override
  Future<Profile> getProfile() async {
    throw const ApiException("Couldn't connect.");
  }

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) async {
    throw const ApiException("Couldn't connect.");
  }

  @override
  Future<Profile> uploadProfilePicture(File file) async {
    throw const ApiException("Couldn't connect.");
  }
}

/// Covers Profile navigation (from Chat's header avatar and the bottom
/// nav), that it shows the real authenticated user's details rather than
/// anything hardcoded, and that logout actually navigates back to Login.
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

  testWidgets(
    "tapping Chat's header avatar opens Profile with the real user's details",
    (tester) async {
      await openChat(tester);

      await tester.tap(find.bySemanticsLabel('Open profile'));
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

  testWidgets(
    "when /api/profile is down (initial load and its one retry both fail), "
    "Profile still shows the signed-in user's name/username/email from the "
    'already-authenticated session instead of going blank',
    (tester) async {
      await pumpApp(
        tester,
        overrides: [
          statementFilePickerServiceProvider.overrideWithValue(
            FakeStatementFilePickerService(),
          ),
          chatRepositoryProvider.overrideWithValue(MockChatRepository()),
        ],
        profileRepository: _AlwaysFailingProfileRepository(),
      );
      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Open profile'));
      await tester.pumpAndSettle();

      // Same demo-account identity as the happy-path test above, but
      // sourced from `authControllerProvider`'s cached `AuthUser` since
      // `/api/profile` never actually succeeded here.
      expect(find.text('Mustapha Ambali'), findsOneWidget);
      expect(find.text('@mustapha'), findsOneWidget);
      expect(find.text('demo@finassist.com'), findsOneWidget);
    },
  );

  testWidgets('tapping the "Profile" bottom nav tab opens Profile', (
    tester,
  ) async {
    await openChat(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('@mustapha'), findsOneWidget);
  });

  testWidgets(
    'the bottom navigation bar stays visible after switching to Profile',
    (tester) async {
      await openChat(tester);

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

  testWidgets('"Appearance" opens the theme picker bottom sheet', (
    tester,
  ) async {
    await openChat(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final appearanceRow = find.text('Appearance');
    await tester.dragUntilVisible(
      appearanceRow,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    await tester.tap(appearanceRow);
    await tester.pumpAndSettle();

    expect(find.text('Choose how FinAssist looks'), findsOneWidget);
    // "System" also matches the Appearance row's own current-value subtitle
    // underneath the sheet, so at least one (not exactly one) is expected.
    expect(find.text('System'), findsAtLeastNWidgets(1));
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets(
    'Profile has no separate Documents entry — documents live inside their '
    'conversation, not a Profile document-management screen',
    (tester) async {
      await openChat(tester);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      // The whole page is short enough now (no Documents row) that nothing
      // further below needs scrolling into view to make this assertion.
      expect(find.text('Documents'), findsNothing);
    },
  );

  testWidgets('logging out clears the session and returns to Login', (
    tester,
  ) async {
    await openChat(tester);

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

    expect(find.text('Log out of FinAssist?'), findsOneWidget);
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
