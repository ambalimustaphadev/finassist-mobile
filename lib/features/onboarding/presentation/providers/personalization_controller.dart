import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../profile/presentation/providers/profile_controller.dart';

/// Maps Page 2's "About you" options to the backend's real
/// `employment_status` enum (`employed`/`self_employed`/`unemployed`/
/// `student`/`retired`/`other` — `Profile.employmentStatusOptions`).
/// "Business owner" has no dedicated backend value; `self_employed` is the
/// closest honest match (a business owner works for themselves) rather
/// than a fabricated new enum value.
const _situationToEmploymentStatus = {
  'Student': 'student',
  'Employed': 'employed',
  'Self-employed': 'self_employed',
  'Business owner': 'self_employed',
  'Other': 'other',
};

/// Maps Page 3's options to the backend's `financial_experience` enum
/// (`beginner`/`some_knowledge`/`moderate`/`advanced`).
const _experienceToBackend = {
  'Beginner': 'beginner',
  'Some knowledge': 'some_knowledge',
  'Moderate': 'moderate',
  'Advanced': 'advanced',
};

/// Maps Page 5's options to the backend's `response_style` enum
/// (`simple`/`balanced`/`detailed`).
const _responseStyleToBackend = {
  'Simple and clear': 'simple',
  'Balanced': 'balanced',
  'Detailed': 'detailed',
};

/// Maps Page 4's conversation-topic options to the exact stable,
/// snake_case values the backend's `interests` contract accepts.
const _interestToBackend = {
  'General money questions': 'general_money_questions',
  'Understanding documents': 'understanding_documents',
  'Planning for life decisions': 'planning_life_decisions',
  'Financial concepts': 'financial_concepts',
  'Comparing options': 'comparing_options',
  'Tax-related questions': 'tax_questions',
  'Other': 'other',
};

class PersonalizationState {
  const PersonalizationState({
    this.situation,
    this.experience,
    this.interests = const {},
    this.responseStyle,
    this.proactiveSuggestions = true,
    this.isSaving = false,
    this.saveError,
    this.completed = false,
  });

  final String? situation;
  final String? experience;
  final Set<String> interests;
  final String? responseStyle;
  final bool proactiveSuggestions;

  final bool isSaving;
  final String? saveError;

  /// Whether `completeSetup` has already succeeded — `AuthGate` reacts to
  /// the real backend-authoritative `onboarding_completed` flag, not this;
  /// this only prevents this controller from re-submitting the same PATCHes
  /// a second time on repeated "Continue to FinAssist" taps.
  final bool completed;

  PersonalizationState copyWith({
    String? situation,
    String? experience,
    Set<String>? interests,
    String? responseStyle,
    bool? proactiveSuggestions,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
    bool? completed,
  }) {
    return PersonalizationState(
      situation: situation ?? this.situation,
      experience: experience ?? this.experience,
      interests: interests ?? this.interests,
      responseStyle: responseStyle ?? this.responseStyle,
      proactiveSuggestions: proactiveSuggestions ?? this.proactiveSuggestions,
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      completed: completed ?? this.completed,
    );
  }
}

/// Rebuilt per authenticated user, same pattern as `profileControllerProvider`
/// et al. — a fresh personalization pass never inherits another account's
/// half-finished answers.
final personalizationControllerProvider =
    StateNotifierProvider.autoDispose<
      PersonalizationController,
      PersonalizationState
    >((ref) => PersonalizationController(ref));

/// Owns every answer collected across the personalization flow's 5
/// question screens so back/forward navigation between them (a plain
/// `PageView`, not separate pushed routes) never loses state, and performs
/// the actual backend save when the user taps "Continue to FinAssist" on
/// the completion page.
///
/// [situation] persists to `Profile.employmentStatus` via `PATCH
/// /api/profile`. [experience], [interests], [responseStyle] and
/// [proactiveSuggestions] persist to `financial_experience`/`interests`/
/// `response_style`/`proactive_suggestions` via `PATCH /api/preferences`
/// (see `Preferences`) — the backend now accepts all four. Selecting an
/// option never calls either endpoint by itself; both PATCHes happen once,
/// together, from [completeSetup].
class PersonalizationController extends StateNotifier<PersonalizationState> {
  PersonalizationController(this._ref) : super(const PersonalizationState());

  final Ref _ref;

  void setSituation(String value) => state = state.copyWith(situation: value);

  void setExperience(String value) => state = state.copyWith(experience: value);

  void toggleInterest(String value) {
    final next = Set<String>.of(state.interests);
    if (!next.remove(value)) next.add(value);
    state = state.copyWith(interests: next);
  }

  void setResponseStyle(String value) =>
      state = state.copyWith(responseStyle: value);

  void setProactiveSuggestions(bool value) =>
      state = state.copyWith(proactiveSuggestions: value);

  void dismissError() => state = state.copyWith(clearSaveError: true);

  /// Persists whatever the user actually provided and marks onboarding
  /// complete — the single save operation behind "Continue to FinAssist"
  /// on the completion page.
  ///
  /// Order matters: the four preference fields are saved *before* the
  /// profile PATCH that flips `onboarding_completed`, so a failure while
  /// saving preferences can never leave onboarding marked complete with
  /// unsaved preferences — `AuthGate` only reveals Chat once
  /// `onboarding_completed` is true, so this ordering is what actually
  /// keeps a failed save on the completion screen rather than letting the
  /// user in with silently-dropped answers.
  Future<bool> completeSetup() async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearSaveError: true);

    final preferenceChanges = <String, dynamic>{
      'proactive_suggestions': state.proactiveSuggestions,
    };
    final financialExperience = _experienceToBackend[state.experience];
    if (financialExperience != null) {
      preferenceChanges['financial_experience'] = financialExperience;
    }
    final responseStyle = _responseStyleToBackend[state.responseStyle];
    if (responseStyle != null) {
      preferenceChanges['response_style'] = responseStyle;
    }
    if (state.interests.isNotEmpty) {
      preferenceChanges['interests'] = state.interests
          .map((interest) => _interestToBackend[interest] ?? interest)
          .toList();
    }

    final preferencesSaved = await _ref
        .read(preferencesControllerProvider.notifier)
        .update(preferenceChanges);

    if (!preferencesSaved) {
      state = state.copyWith(
        isSaving: false,
        saveError:
            _ref.read(preferencesControllerProvider).saveError ??
            "Couldn't save this yet. Please check your connection and try "
                'again.',
      );
      return false;
    }

    final profileChanges = <String, dynamic>{'onboarding_completed': true};
    final employmentStatus = _situationToEmploymentStatus[state.situation];
    if (employmentStatus != null) {
      profileChanges['employment_status'] = employmentStatus;
    }

    final profileSaved = await _ref
        .read(profileControllerProvider.notifier)
        .updateProfile(profileChanges);

    if (!profileSaved) {
      state = state.copyWith(
        isSaving: false,
        saveError:
            _ref.read(profileControllerProvider).saveError ??
            "Couldn't save this yet. Please check your connection and try "
                'again.',
      );
      return false;
    }

    state = state.copyWith(isSaving: false, completed: true);
    return true;
  }
}
