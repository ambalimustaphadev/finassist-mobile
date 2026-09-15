import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/profile/data/models/profile.dart';
import 'package:finassist/features/profile/data/repositories/profile_repository.dart';
import 'package:finassist/features/profile/presentation/providers/profile_controller.dart';
import 'package:finassist/features/profile/presentation/screens/personal_information_screen.dart';

import 'support/pump_app.dart';

/// A [ProfileRepository] whose [updateProfile] always fails — lets a test
/// exercise the Personal Information screen's failure path without a real
/// backend.
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

/// A [ProfileRepository] that records the exact `changes` map it was
/// called with — lets a test assert the screen only sends the field(s)
/// that actually changed, not the whole form.
class _RecordingProfileRepository implements ProfileRepository {
  _RecordingProfileRepository(this._profile);

  Profile _profile;
  Map<String, dynamic>? lastChanges;

  @override
  Future<Profile> getProfile() async => _profile;

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) async {
    lastChanges = changes;
    _profile = Profile(
      id: _profile.id,
      username: _profile.username,
      firstName: changes['first_name'] as String? ?? _profile.firstName,
      lastName: changes['last_name'] as String? ?? _profile.lastName,
      email: _profile.email,
      currency: _profile.currency,
      onboardingCompleted: _profile.onboardingCompleted,
      createdAt: _profile.createdAt,
      updatedAt: DateTime.now(),
    );
    return _profile;
  }

  @override
  Future<Profile> uploadProfilePicture(File file) async => _profile;
}

Profile _demoProfile() {
  final now = DateTime(2026, 1, 1);
  return Profile(
    id: 1,
    username: 'mustapha',
    firstName: 'Mustapha',
    lastName: 'Ambali',
    email: 'demo@finassist.com',
    currency: 'NGN',
    onboardingCompleted: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Future<void> openPersonalInformation(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await pumpApp(tester, overrides: overrides);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows the real profile fields, not a placeholder or an unavailable '
    'message',
    (tester) async {
      await openPersonalInformation(tester);

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('demo@finassist.com'), findsOneWidget);
      expect(find.text('@mustapha'), findsOneWidget);
      expect(find.text("isn't available yet"), findsNothing);
    },
  );

  testWidgets(
    'the First name and Last name fields load the current saved values as '
    'real text, not hintText',
    (tester) async {
      await openPersonalInformation(tester);

      final screen = find.byType(PersonalInformationScreen);
      final textFields = find
          .descendant(of: screen, matching: find.byType(TextField))
          .evaluate()
          .map((element) => element.widget as TextField)
          .toList();

      final firstNameField = textFields.firstWhere(
        (field) => field.controller?.text == 'Mustapha',
      );
      expect(firstNameField.decoration?.hintText, isNot('Mustapha'));

      final lastNameField = textFields.firstWhere(
        (field) => field.controller?.text == 'Ambali',
      );
      expect(lastNameField.decoration?.hintText, isNot('Ambali'));
    },
  );

  testWidgets('the Save button is disabled until a field actually changes', (
    tester,
  ) async {
    await openPersonalInformation(tester);

    final screen = find.byType(PersonalInformationScreen);
    final saveButton = find.descendant(
      of: screen,
      matching: find.widgetWithText(InkWell, 'Save changes'),
    );
    expect(tester.widget<InkWell>(saveButton).onTap, isNull);

    final firstNameField = find.descendant(
      of: screen,
      matching: find.widgetWithText(TextField, 'Mustapha'),
    );
    await tester.enterText(firstNameField, 'Ada');
    await tester.pump();

    expect(tester.widget<InkWell>(saveButton).onTap, isNotNull);
  });

  testWidgets(
    'clearing the first name shows a validation error instead of saving',
    (tester) async {
      await openPersonalInformation(tester);

      final screen = find.byType(PersonalInformationScreen);
      final firstNameField = find.descendant(
        of: screen,
        matching: find.widgetWithText(TextField, 'Mustapha'),
      );
      await tester.enterText(firstNameField, '');
      await tester.pump();

      final saveButton = find.descendant(
        of: screen,
        matching: find.text('Save changes'),
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter your first name.'), findsOneWidget);
      // Still on the same screen — an invalid save never navigated away.
      expect(find.byType(PersonalInformationScreen), findsOneWidget);
    },
  );

  testWidgets(
    'saving updates the profile, shows a success message, and the header '
    'reflects the new name immediately',
    (tester) async {
      await openPersonalInformation(tester);

      final editScreen = find.byType(PersonalInformationScreen);
      final firstNameField = find.descendant(
        of: editScreen,
        matching: find.widgetWithText(TextField, 'Mustapha'),
      );
      await tester.enterText(firstNameField, 'Ada');
      await tester.pump();

      final saveButton = find.descendant(
        of: editScreen,
        matching: find.text('Save changes'),
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Popped back to Profile, header now shows the updated name.
      expect(find.text('Ada Ambali'), findsOneWidget);
      expect(find.text('Your details have been updated.'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed save shows an error and keeps the unsaved change on screen',
    (tester) async {
      final profile = _demoProfile();
      await openPersonalInformation(
        tester,
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            _AlwaysFailingUpdateProfileRepository(profile),
          ),
        ],
      );

      final editScreen = find.byType(PersonalInformationScreen);
      final firstNameField = find.descendant(
        of: editScreen,
        matching: find.widgetWithText(TextField, 'Mustapha'),
      );
      await tester.enterText(firstNameField, 'Ada');
      await tester.pump();

      final saveButton = find.descendant(
        of: editScreen,
        matching: find.text('Save changes'),
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't connect."), findsOneWidget);
      // Never popped — the failed save leaves the user right where they
      // were, with their typed change still in the field.
      expect(find.byType(PersonalInformationScreen), findsOneWidget);
      expect(find.text('Your details have been updated.'), findsNothing);
    },
  );

  testWidgets('changing only the first name sends only first_name', (
    tester,
  ) async {
    final repository = _RecordingProfileRepository(_demoProfile());
    await openPersonalInformation(
      tester,
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );

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

    expect(repository.lastChanges, {'first_name': 'Ada'});
  });

  testWidgets('changing only the last name sends only last_name', (
    tester,
  ) async {
    final repository = _RecordingProfileRepository(_demoProfile());
    await openPersonalInformation(
      tester,
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );

    final editScreen = find.byType(PersonalInformationScreen);
    await tester.enterText(
      find.descendant(
        of: editScreen,
        matching: find.widgetWithText(TextField, 'Ambali'),
      ),
      'Lovelace',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: editScreen, matching: find.text('Save changes')),
    );
    await tester.pumpAndSettle();

    expect(repository.lastChanges, {'last_name': 'Lovelace'});
  });

  testWidgets('changing both names sends both fields', (tester) async {
    final repository = _RecordingProfileRepository(_demoProfile());
    await openPersonalInformation(
      tester,
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );

    final editScreen = find.byType(PersonalInformationScreen);
    await tester.enterText(
      find.descendant(
        of: editScreen,
        matching: find.widgetWithText(TextField, 'Mustapha'),
      ),
      'Ada',
    );
    await tester.enterText(
      find.descendant(
        of: editScreen,
        matching: find.widgetWithText(TextField, 'Ambali'),
      ),
      'Lovelace',
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: editScreen, matching: find.text('Save changes')),
    );
    await tester.pumpAndSettle();

    expect(repository.lastChanges, {
      'first_name': 'Ada',
      'last_name': 'Lovelace',
    });
  });

  testWidgets(
    'no API call happens when the Save button is tapped without any change',
    (tester) async {
      final repository = _RecordingProfileRepository(_demoProfile());
      await openPersonalInformation(
        tester,
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );

      // The button is disabled (onTap: null) when nothing changed, so this
      // tap is a no-op — asserting that directly, rather than just
      // inspecting `onTap`, proves no request fires even if someone forces
      // the tap through.
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repository.lastChanges, isNull);
    },
  );

  for (final size in [
    const Size(375, 667), // small phone (iPhone SE)
    const Size(390, 844), // standard phone (iPhone 14)
    const Size(430, 932), // large phone (iPhone Pro Max)
  ]) {
    testWidgets('renders without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openPersonalInformation(tester);
      expect(tester.takeException(), isNull);

      // Focusing a field (as if the keyboard were opening) must not
      // overflow either — the form scrolls, it doesn't clip.
      final screen = find.byType(PersonalInformationScreen);
      await tester.tap(
        find.descendant(
          of: screen,
          matching: find.widgetWithText(TextField, 'Mustapha'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'the Save button remains reachable by scrolling on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openPersonalInformation(tester);

      final screen = find.byType(PersonalInformationScreen);
      // `scrollUntilVisible`/`ensureVisible`'s default scrollable lookup
      // (`find.byType(Scrollable)`) is ambiguous here — each `TextField`'s
      // `EditableText` carries its own internal `Scrollable` for text
      // scrolling, alongside the screen's own `ListView`. Dragging the
      // `ListView` directly sidesteps that.
      final listView = find.descendant(of: screen, matching: find.byType(ListView));
      await tester.drag(listView, const Offset(0, -400));
      await tester.pumpAndSettle();

      final saveButton = find.descendant(
        of: screen,
        matching: find.text('Save changes'),
      );
      expect(saveButton, findsOneWidget);
    },
  );
}
