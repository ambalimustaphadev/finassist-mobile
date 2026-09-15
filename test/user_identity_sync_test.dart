import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/core/services/greeting_service.dart';
import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/profile/data/models/profile.dart';
import 'package:finassist/features/profile/data/repositories/profile_repository.dart';
import 'package:finassist/features/profile/presentation/providers/profile_controller.dart';
import 'package:finassist/features/profile/presentation/screens/personal_information_screen.dart';

import 'support/pump_app.dart';

/// A [ProfileRepository] whose [updateProfile] always fails — used to
/// prove a failed save never touches the shared identity state that Chat
/// and the drawer read from.
class _AlwaysFailingUpdateProfileRepository implements ProfileRepository {
  _AlwaysFailingUpdateProfileRepository(this._profile);

  final Profile _profile;

  @override
  Future<Profile> getProfile() async => _profile;

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) async {
    throw const ApiException("Couldn't connect.");
  }

  @override
  Future<Profile> uploadProfilePicture(File file) async => _profile;
}

/// This suite covers the cross-app consequence of a Personal Information
/// save, not the form itself (see `personal_information_screen_test.dart`
/// for that): once `first_name`/`last_name` change, every screen that
/// displays the user's identity — the Chat greeting, the chat drawer's
/// profile footer — must reflect it immediately, with no logout/restart/
/// manual refresh, because they all read the same
/// `currentUserIdentityProvider` (backed by `profileControllerProvider`)
/// rather than a separate, independently-updated copy.
void main() {
  Future<void> openChat(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
  }) async {
    await pumpApp(
      tester,
      overrides: [
        chatRepositoryProvider.overrideWithValue(MockChatRepository()),
        ...extraOverrides,
      ],
    );
    // Chat is the landing tab — no navigation needed to reach it.
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.text('What would you like to know today?'));
  }

  Future<void> editNameAndSave(
    WidgetTester tester, {
    required String newFirstName,
  }) async {
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();

    final editScreen = find.byType(PersonalInformationScreen);
    await tester.enterText(
      find.descendant(
        of: editScreen,
        matching: find.widgetWithText(TextField, 'Mustapha'),
      ),
      newFirstName,
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: editScreen, matching: find.text('Save changes')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the Chat greeting shows the current first name on login',
    (tester) async {
      await openChat(tester);

      final greetingWord = GreetingService.greetingFor(DateTime.now());
      expect(
        find.text('$greetingWord,\nMustapha.', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'saving a new first name in Personal Information updates the Chat '
    'greeting immediately, with no logout/restart/manual refresh — just '
    'switching back to the Chat tab',
    (tester) async {
      await openChat(tester);

      await editNameAndSave(tester, newFirstName: 'Mustapha Ade');
      // Back on Profile (the save popped Personal Information) — switching
      // to Chat is ordinary navigation, not a reload of any kind.
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      final greetingWord = GreetingService.greetingFor(DateTime.now());
      expect(
        find.text('$greetingWord,\nMustapha Ade.', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('$greetingWord,\nMustapha.', findRichText: true),
        findsNothing,
      );
    },
  );

  testWidgets(
    'the chat drawer profile footer also reflects the updated name',
    (tester) async {
      await openChat(tester);

      await editNameAndSave(tester, newFirstName: 'Ada');
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ada Ambali'), findsOneWidget);
      expect(find.text('Mustapha Ambali'), findsNothing);
    },
  );

  testWidgets(
    'a failed save leaves the shared identity state untouched — the Chat '
    'greeting keeps showing the original name',
    (tester) async {
      final profile = Profile(
        id: 1,
        username: 'mustapha',
        firstName: 'Mustapha',
        lastName: 'Ambali',
        email: 'demo@finassist.com',
        currency: 'NGN',
        onboardingCompleted: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await openChat(
        tester,
        extraOverrides: [
          profileRepositoryProvider.overrideWithValue(
            _AlwaysFailingUpdateProfileRepository(profile),
          ),
        ],
      );

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Personal information'));
      await tester.pumpAndSettle();

      final editScreen = find.byType(PersonalInformationScreen);
      await tester.enterText(
        find.descendant(
          of: editScreen,
          matching: find.widgetWithText(TextField, 'Mustapha'),
        ),
        'Ada',
      );
      await tester.pump();
      await tester.tap(
        find.descendant(of: editScreen, matching: find.text('Save changes')),
      );
      await tester.pumpAndSettle();
      // The failed save never popped, and the typed-but-unsaved "Ada" is
      // still in the field — leaving now goes through the same "Discard
      // changes?" confirmation any unsaved edit triggers. The screen's
      // back arrow is a plain `IconButton`, not a framework `BackButton`,
      // so it's targeted by icon rather than `tester.pageBack()`.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      final greetingWord = GreetingService.greetingFor(DateTime.now());
      expect(
        find.text('$greetingWord,\nMustapha.', findRichText: true),
        findsOneWidget,
      );
    },
  );
}
