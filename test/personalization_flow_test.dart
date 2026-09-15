import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/onboarding/presentation/providers/personalization_controller.dart';
import 'package:finassist/features/profile/data/models/preferences.dart';
import 'package:finassist/features/profile/data/models/profile.dart';
import 'package:finassist/features/profile/data/repositories/preference_repository.dart';
import 'package:finassist/features/profile/data/repositories/profile_repository.dart';

import 'support/pump_app.dart';

/// Wraps a real `FakeProfileRepository`-style profile but fails the first
/// `updateProfile` call with a network-style `ApiException` before
/// succeeding on every call after — lets a test drive the exact "backend
/// unavailable, then Retry" path `PersonalizationController.completeSetup`
/// is meant to handle, without touching real HTTP.
class _FlakyProfileRepository implements ProfileRepository {
  _FlakyProfileRepository(this._delegate);

  final ProfileRepository _delegate;
  var _remainingFailures = 1;

  @override
  Future<Profile> getProfile() => _delegate.getProfile();

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) {
    if (_remainingFailures > 0) {
      _remainingFailures--;
      throw const ApiException(
        "Couldn't connect. Please check your connection and try again.",
      );
    }
    return _delegate.updateProfile(changes);
  }

  @override
  Future<Profile> uploadProfilePicture(File file) =>
      _delegate.uploadProfilePicture(file);
}

/// Same "fail once, then succeed" shape as [_FlakyProfileRepository], for
/// the `PATCH /api/preferences` leg of `completeSetup`.
class _FlakyPreferenceRepository implements PreferenceRepository {
  _FlakyPreferenceRepository(this._delegate);

  final PreferenceRepository _delegate;
  var _remainingFailures = 1;

  @override
  Future<Preferences> getPreferences() => _delegate.getPreferences();

  @override
  Future<Preferences> updatePreferences(Map<String, dynamic> changes) {
    if (_remainingFailures > 0) {
      _remainingFailures--;
      throw const ApiException(
        "Couldn't connect. Please check your connection and try again.",
      );
    }
    return _delegate.updatePreferences(changes);
  }
}

/// Records every `changes` map passed to `updatePreferences`/`updateProfile`
/// — lets a test assert exactly when (and how many times, and with what
/// payload) each endpoint was actually called, not just the resulting
/// state.
class _RecordingPreferenceRepository implements PreferenceRepository {
  _RecordingPreferenceRepository(this._delegate);

  final PreferenceRepository _delegate;
  final calls = <Map<String, dynamic>>[];

  @override
  Future<Preferences> getPreferences() => _delegate.getPreferences();

  @override
  Future<Preferences> updatePreferences(Map<String, dynamic> changes) {
    calls.add(changes);
    return _delegate.updatePreferences(changes);
  }
}

class _RecordingProfileRepository implements ProfileRepository {
  _RecordingProfileRepository(this._delegate);

  final ProfileRepository _delegate;
  final calls = <Map<String, dynamic>>[];

  @override
  Future<Profile> getProfile() => _delegate.getProfile();

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) {
    calls.add(changes);
    return _delegate.updateProfile(changes);
  }

  @override
  Future<Profile> uploadProfilePicture(File file) =>
      _delegate.uploadProfilePicture(file);
}

/// For options inside a question screen's scrollable body, which may sit
/// below the fold.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// For the scaffold's own Skip/Continue/Back — always on-screen already,
/// so no `ensureVisible` here. `ensureVisible` walks every ancestor
/// `Scrollable`, including the hosting `PageView` itself; since these
/// buttons are themselves part of each page's horizontally-scrolled
/// content, asking to "ensure" them visible can nudge the `PageView`'s own
/// scroll offset and snap it onto the next page before the tap even
/// happens — a real, if easily missed, hazard for driving PageView-hosted
/// screens in tests, not merely a style preference.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// `PageView`'s cache extent keeps the not-yet-visible adjacent screen
/// built alongside the current one, so a plain `find.text('Skip')`/
/// `find.text('Continue')` can match more than one `PersonalizationScaffold`
/// at once. Each scaffold's Skip/Continue/Back carries a step-scoped key
/// specifically so tests can target the currently-visible one unambiguously.
Finder _skipButton(int step) => find.byKey(Key('personalization-skip-$step'));
Finder _continueButton(int step) =>
    find.byKey(Key('personalization-continue-$step'));
Finder _backButton(int step) => find.byKey(Key('personalization-back-$step'));
final _editButton = find.byKey(const Key('personalization-edit'));

void main() {
  Profile incompleteProfile() {
    final now = DateTime(2026, 1, 1);
    return Profile(
      id: 1,
      username: 'mustapha',
      firstName: 'Mustapha',
      lastName: 'Ambali',
      email: 'demo@finassist.com',
      currency: 'NGN',
      onboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> loginAndEnterFlow(
    WidgetTester tester, {
    ProfileRepository? profileRepository,
    PreferenceRepository? preferenceRepository,
  }) async {
    await pumpApp(
      tester,
      profileRepository:
          profileRepository ??
          FakeProfileRepository(initialProfile: incompleteProfile()),
      preferenceRepository: preferenceRepository,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'demo@finassist.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.pump();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a first-time authenticated session sees the personalization flow, '
    'starting on Page 1 (the introduction) before Chat',
    (tester) async {
      await loginAndEnterFlow(tester);

      expect(
        find.text("Let's personalize\nFinAssist for you."),
        findsOneWidget,
      );
      expect(find.text('1 of 6'), findsOneWidget);
      expect(find.byKey(const Key('mainShellScreen')), findsNothing);
      // Nothing precedes Page 1 — no back arrow.
      expect(_backButton(1), findsNothing);
    },
  );

  testWidgets('Page 2 (About you) is single-select, and Continue stays '
      'locked until something is selected', (tester) async {
    await loginAndEnterFlow(tester);
    await _tap(tester, _continueButton(1));
    expect(find.text('2 of 6'), findsOneWidget);

    await _tap(tester, _continueButton(2));
    expect(find.text('2 of 6'), findsOneWidget); // still on page 2

    await _tapVisible(tester, find.text('Student'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await _tap(tester, _continueButton(2));
    expect(find.text('3 of 6'), findsOneWidget);
  });

  testWidgets('Page 3 (Your experience) is single-select', (tester) async {
    await loginAndEnterFlow(tester);
    await _tap(tester, _continueButton(1));
    await _tapVisible(tester, find.text('Student'));
    await _tap(tester, _continueButton(2));
    expect(find.text('3 of 6'), findsOneWidget);

    await _tap(tester, _continueButton(3));
    expect(find.text('3 of 6'), findsOneWidget);

    await _tapVisible(tester, find.text('Beginner'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await _tap(tester, _continueButton(3));
    expect(find.text('4 of 6'), findsOneWidget);
  });

  testWidgets(
    'Page 4 (Your interests) supports multiple selections, and Continue '
    'requires at least one',
    (tester) async {
      await loginAndEnterFlow(tester);
      await _tap(tester, _continueButton(1));
      await _tapVisible(tester, find.text('Student'));
      await _tap(tester, _continueButton(2));
      await _tapVisible(tester, find.text('Beginner'));
      await _tap(tester, _continueButton(3));
      expect(find.text('4 of 6'), findsOneWidget);

      await _tap(tester, _continueButton(4));
      expect(find.text('4 of 6'), findsOneWidget);

      await _tapVisible(tester, find.text('Financial concepts'));
      await _tapVisible(tester, find.text('Understanding documents'));
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));

      await _tap(tester, _continueButton(4));
      expect(find.text('5 of 6'), findsOneWidget);
    },
  );

  testWidgets('Page 5 (Response style) is single-select, and the proactive '
      "suggestions toggle defaults on and can be switched off", (tester) async {
    await loginAndEnterFlow(tester);
    await _tap(tester, _continueButton(1));
    await _tapVisible(tester, find.text('Student'));
    await _tap(tester, _continueButton(2));
    await _tapVisible(tester, find.text('Beginner'));
    await _tap(tester, _continueButton(3));
    await _tapVisible(tester, find.text('Financial concepts'));
    await _tap(tester, _continueButton(4));
    expect(find.text('5 of 6'), findsOneWidget);

    await _tap(tester, _continueButton(5));
    expect(find.text('5 of 6'), findsOneWidget); // no response style yet

    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
    await _tapVisible(tester, find.byType(Switch));

    await _tapVisible(tester, find.text('Simple and clear'));
    await _tap(tester, _continueButton(5));
    expect(find.text('6 of 6'), findsOneWidget);
  });

  testWidgets(
    'Page 6 summary reflects the actual selections made, not hardcoded '
    'text, and Edit returns to the flow with earlier answers preserved',
    (tester) async {
      await loginAndEnterFlow(tester);
      await _tap(tester, _continueButton(1));
      await _tapVisible(tester, find.text('Business owner'));
      await _tap(tester, _continueButton(2));
      await _tapVisible(tester, find.text('Advanced'));
      await _tap(tester, _continueButton(3));
      await _tapVisible(tester, find.text('Comparing options'));
      await _tap(tester, _continueButton(4));
      await _tapVisible(tester, find.text('Detailed'));
      await _tap(tester, _continueButton(5));

      expect(find.text("You're all set!"), findsOneWidget);
      expect(find.text('Business owner'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Comparing options'), findsOneWidget);
      expect(find.text('Detailed'), findsOneWidget);
      // Never the old goal-tracking/dashboard product.
      expect(find.text('Student'), findsNothing);
      expect(find.textContaining('goal'), findsNothing);

      await _tap(tester, _editButton);
      expect(find.text('2 of 6'), findsOneWidget);
      // The earlier selection is still applied, not reset.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Business owner'), findsOneWidget);
    },
  );

  testWidgets('Back from Page 2 returns to Page 1, and Back within the flow '
      'preserves earlier answers', (tester) async {
    await loginAndEnterFlow(tester);
    await _tap(tester, _continueButton(1));
    await _tapVisible(tester, find.text('Employed'));
    await _tap(tester, _continueButton(2));
    expect(find.text('3 of 6'), findsOneWidget);

    await _tap(tester, _backButton(3));
    expect(find.text('2 of 6'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Employed'), findsOneWidget);

    await _tap(tester, _backButton(2));
    expect(find.text("Let's personalize\nFinAssist for you."), findsOneWidget);
  });

  testWidgets(
    'Skip from any question jumps straight to the completion page without '
    'saving, and completing it there persists real profile fields — never '
    'creating a goal (Goals is not part of FinAssist anymore)',
    (tester) async {
      final repo = FakeProfileRepository(initialProfile: incompleteProfile());
      await loginAndEnterFlow(tester, profileRepository: repo);

      // The very first question's Skip — nothing has been answered yet.
      await _tap(tester, _skipButton(1));
      expect(find.text("You're all set!"), findsOneWidget);

      // Nothing was persisted yet — only tapping "Continue to FinAssist"
      // actually saves.
      expect((await repo.getProfile()).onboardingCompleted, isFalse);

      await _tap(tester, find.text('Continue to FinAssist'));

      expect((await repo.getProfile()).onboardingCompleted, isTrue);
      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
      expect(find.textContaining('goal'), findsNothing);
    },
  );

  testWidgets(
    'completing all 5 questions persists the real employment_status field '
    'and lands on Chat, never a dashboard',
    (tester) async {
      final repo = FakeProfileRepository(initialProfile: incompleteProfile());
      await loginAndEnterFlow(tester, profileRepository: repo);

      await _tap(tester, _continueButton(1));
      await _tapVisible(tester, find.text('Self-employed'));
      await _tap(tester, _continueButton(2));
      await _tapVisible(tester, find.text('Moderate'));
      await _tap(tester, _continueButton(3));
      await _tapVisible(tester, find.text('General money questions'));
      await _tap(tester, _continueButton(4));
      await _tapVisible(tester, find.text('Balanced'));
      await _tap(tester, _continueButton(5));

      await _tap(tester, find.text('Continue to FinAssist'));

      final saved = await repo.getProfile();
      expect(saved.onboardingCompleted, isTrue);
      expect(saved.employmentStatus, 'self_employed');
      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
    },
  );

  testWidgets(
    'a backend failure while completing setup shows a scoped, retryable '
    'message — not a global connection-error screen — and Retry succeeds',
    (tester) async {
      final flaky = _FlakyProfileRepository(
        FakeProfileRepository(initialProfile: incompleteProfile()),
      );
      await loginAndEnterFlow(tester, profileRepository: flaky);

      await _tap(tester, _skipButton(1));
      expect(find.text("You're all set!"), findsOneWidget);

      await _tap(tester, find.text('Continue to FinAssist'));

      expect(
        find.text(
          "Couldn't connect. Please check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.text('SocketException'), findsNothing);
      expect(find.text("You're all set!"), findsOneWidget);

      await _tap(tester, find.text('Retry'));
      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
    },
  );

  testWidgets(
    'selecting options never calls PATCH /api/preferences — only tapping '
    '"Continue to FinAssist" on the completion page does',
    (tester) async {
      final recording = _RecordingPreferenceRepository(
        FakePreferenceRepository(),
      );
      await loginAndEnterFlow(
        tester,
        profileRepository: FakeProfileRepository(
          initialProfile: incompleteProfile(),
        ),
        preferenceRepository: recording,
      );

      await _tap(tester, _continueButton(1));
      await _tapVisible(tester, find.text('Student'));
      expect(recording.calls, isEmpty);
      await _tap(tester, _continueButton(2));
      await _tapVisible(tester, find.text('Beginner'));
      expect(recording.calls, isEmpty);
      await _tap(tester, _continueButton(3));
      await _tapVisible(tester, find.text('Financial concepts'));
      expect(recording.calls, isEmpty);
      await _tap(tester, _continueButton(4));
      await _tapVisible(tester, find.text('Simple and clear'));
      expect(recording.calls, isEmpty);
      await _tap(tester, _continueButton(5));
      expect(recording.calls, isEmpty);

      await _tap(tester, find.text('Continue to FinAssist'));
      expect(recording.calls, hasLength(1));
    },
  );

  testWidgets('completing setup sends the exact backend field mapping for '
      'experience, interests, response style and proactive suggestions '
      'together in one PATCH /api/preferences call', (tester) async {
    final recording = _RecordingPreferenceRepository(
      FakePreferenceRepository(),
    );
    await loginAndEnterFlow(
      tester,
      profileRepository: FakeProfileRepository(
        initialProfile: incompleteProfile(),
      ),
      preferenceRepository: recording,
    );

    await _tap(tester, _continueButton(1));
    await _tapVisible(tester, find.text('Student'));
    await _tap(tester, _continueButton(2));
    await _tapVisible(tester, find.text('Advanced'));
    await _tap(tester, _continueButton(3));
    await _tapVisible(tester, find.text('Financial concepts'));
    await _tapVisible(tester, find.text('Comparing options'));
    await _tap(tester, _continueButton(4));
    await _tapVisible(tester, find.text('Detailed'));
    // Switch off the default-on proactive-suggestions toggle.
    await _tapVisible(tester, find.byType(Switch));
    await _tap(tester, _continueButton(5));

    await _tap(tester, find.text('Continue to FinAssist'));

    expect(recording.calls, hasLength(1));
    expect(recording.calls.single, {
      'proactive_suggestions': false,
      'financial_experience': 'advanced',
      'response_style': 'detailed',
      'interests': ['financial_concepts', 'comparing_options'],
    });

    final saved = await recording.getPreferences();
    expect(saved.financialExperience, 'advanced');
    expect(saved.responseStyle, 'detailed');
    expect(saved.interests, ['financial_concepts', 'comparing_options']);
    expect(saved.proactiveSuggestions, isFalse);
  });

  testWidgets(
    'a preferences failure gates onboarding completion — the profile PATCH '
    'that would mark onboarding complete is never even attempted until '
    'preferences actually save',
    (tester) async {
      final flakyPreferences = _FlakyPreferenceRepository(
        FakePreferenceRepository(),
      );
      final recordingProfile = _RecordingProfileRepository(
        FakeProfileRepository(initialProfile: incompleteProfile()),
      );
      await loginAndEnterFlow(
        tester,
        profileRepository: recordingProfile,
        preferenceRepository: flakyPreferences,
      );

      await _tap(tester, _skipButton(1));
      await _tap(tester, find.text('Continue to FinAssist'));

      // The preferences PATCH failed — the profile PATCH (which would set
      // onboarding_completed) must never have been attempted.
      expect(recordingProfile.calls, isEmpty);
      expect(
        (await recordingProfile.getProfile()).onboardingCompleted,
        isFalse,
      );
      expect(find.byKey(const Key('mainShellScreen')), findsNothing);

      await _tap(tester, find.text('Retry'));

      expect(recordingProfile.calls, hasLength(1));
      expect((await recordingProfile.getProfile()).onboardingCompleted, isTrue);
      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
    },
  );

  testWidgets('calling completeSetup a second time while the first is still in '
      'flight is a silent no-op, not a second PATCH /api/preferences '
      'request — the same guard pattern already used for duplicate chat '
      'sends', (tester) async {
    final recording = _RecordingPreferenceRepository(
      FakePreferenceRepository(),
    );
    await loginAndEnterFlow(
      tester,
      profileRepository: FakeProfileRepository(
        initialProfile: incompleteProfile(),
      ),
      preferenceRepository: recording,
    );

    await _tap(tester, _skipButton(1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final notifier = container.read(personalizationControllerProvider.notifier);

    // Fired while the first save is still in flight — must be a silent
    // no-op, not a second PATCH.
    final first = notifier.completeSetup();
    final second = notifier.completeSetup();
    final results = await Future.wait([first, second]);

    expect(recording.calls, hasLength(1));
    expect(results, [true, false]);
  });

  group('Preferences.fromJson', () {
    test('deserializes the 4 personalization fields when present', () {
      final preferences = Preferences.fromJson({
        'currency': 'NGN',
        'language': 'en',
        'notifications_enabled': true,
        'document_notifications': true,
        'financial_experience': 'advanced',
        'interests': ['financial_concepts', 'comparing_options'],
        'response_style': 'detailed',
        'proactive_suggestions': false,
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      expect(preferences.financialExperience, 'advanced');
      expect(preferences.interests, [
        'financial_concepts',
        'comparing_options',
      ]);
      expect(preferences.responseStyle, 'detailed');
      expect(preferences.proactiveSuggestions, isFalse);
    });

    test('an existing user with none of the 4 fields set deserializes to '
        'null (never fabricated) with proactive_suggestions defaulting true, '
        'and never crashes', () {
      final preferences = Preferences.fromJson({
        'currency': 'NGN',
        'language': 'en',
        'notifications_enabled': true,
        'document_notifications': true,
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      expect(preferences.financialExperience, isNull);
      expect(preferences.interests, isNull);
      expect(preferences.responseStyle, isNull);
      expect(preferences.proactiveSuggestions, isTrue);
    });

    test('explicit nulls from the backend also deserialize safely', () {
      final preferences = Preferences.fromJson({
        'currency': 'NGN',
        'language': 'en',
        'notifications_enabled': true,
        'document_notifications': true,
        'financial_experience': null,
        'interests': null,
        'response_style': null,
        'updated_at': '2026-01-01T00:00:00.000Z',
      });

      expect(preferences.financialExperience, isNull);
      expect(preferences.interests, isNull);
      expect(preferences.responseStyle, isNull);
    });
  });
}
