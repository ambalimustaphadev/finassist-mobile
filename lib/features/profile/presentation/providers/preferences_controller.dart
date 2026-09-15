import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/models/preferences.dart';
import '../../data/repositories/api_preference_repository.dart';
import '../../data/repositories/preference_repository.dart';

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return ApiPreferenceRepository(baseUrl: apiBaseUrl);
});

/// Rebuilt whenever the authenticated user changes — same pattern as every
/// other per-user controller in this app. The single source of truth for
/// currency/language/notification-toggle preferences; nothing else keeps
/// its own copy.
final preferencesControllerProvider =
    StateNotifierProvider<PreferencesController, PreferencesState>((ref) {
      final userId =
          ref.watch(authControllerProvider.select((state) => state.user?.id)) ??
          'guest';
      return PreferencesController(
        ref.watch(preferenceRepositoryProvider),
        userId,
      );
    });

enum PreferencesLoadStatus { loading, loaded, error }

class PreferencesState {
  const PreferencesState({
    this.status = PreferencesLoadStatus.loading,
    this.preferences,
    this.loadError,
    this.isSaving = false,
    this.saveError,
  });

  final PreferencesLoadStatus status;
  final Preferences? preferences;
  final String? loadError;
  final bool isSaving;
  final String? saveError;

  /// Falls back to the default currency/language when preferences haven't
  /// loaded yet, so callers never have to null-check just to read these.
  String get currency => preferences?.currency ?? 'NGN';
  String get language => preferences?.language ?? 'en';

  PreferencesState copyWith({
    PreferencesLoadStatus? status,
    Preferences? preferences,
    String? loadError,
    bool clearLoadError = false,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return PreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

class PreferencesController extends StateNotifier<PreferencesState> {
  PreferencesController(this._repository, this._userId)
    : super(const PreferencesState()) {
    _load();
  }

  final PreferenceRepository _repository;
  // ignore: unused_field
  final String _userId;

  Future<void> _load() async {
    state = state.copyWith(
      status: PreferencesLoadStatus.loading,
      clearLoadError: true,
    );
    try {
      final preferences = await _repository.getPreferences();
      state = state.copyWith(
        status: PreferencesLoadStatus.loaded,
        preferences: preferences,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: PreferencesLoadStatus.error,
        loadError: e.message,
      );
    }
  }

  Future<void> refresh() => _load();

  Future<bool> update(Map<String, dynamic> changes) async {
    state = state.copyWith(isSaving: true, clearSaveError: true);
    try {
      final preferences = await _repository.updatePreferences(changes);
      state = state.copyWith(isSaving: false, preferences: preferences);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, saveError: e.message);
      return false;
    }
  }

  Future<bool> setCurrency(String code) => update({'currency': code});

  Future<bool> setLanguage(String code) => update({'language': code});

  void dismissSaveError() => state = state.copyWith(clearSaveError: true);
}
