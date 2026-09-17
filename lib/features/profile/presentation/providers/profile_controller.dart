import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/api_profile_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/profile_image_picker_service.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ApiProfileRepository(baseUrl: apiBaseUrl);
});

/// Swap for a fake in tests — the only thing in the profile feature that
/// talks to platform channels (photo library/camera/file picker +
/// permissions). Kept distinct from [profileControllerProvider]: this only
/// gets a `File` off the device; uploading it is the controller's job.
final profileImagePickerServiceProvider = Provider<ProfileImagePickerService>((
  ref,
) {
  return DeviceProfileImagePickerService();
});

/// Rebuilt whenever the authenticated user changes — same pattern as
/// `chatControllerProvider`/`profileFinanceControllerProvider`, so one
/// user's profile never bleeds into another's session.
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final userId =
          ref.watch(authControllerProvider.select((state) => state.user?.id)) ??
          'guest';
      return ProfileController(ref.watch(profileRepositoryProvider), userId);
    });

/// The one authoritative current identity for display anywhere in the
/// app: the loaded `Profile`'s, falling back to the already-authenticated
/// session's `AuthUser` only until the profile itself has loaded (same
/// fallback `ProfileHeaderCard` already uses). Every UI surface that
/// shows the user's name or email — the Chat greeting, the chat drawer,
/// anything else — should watch this instead of reading
/// `authControllerProvider`'s `AuthUser` directly, so a name saved from
/// Personal Information (which updates [profileControllerProvider]'s
/// state) is reflected everywhere immediately, with no separate stale
/// copy to keep in sync by hand.
final currentUserIdentityProvider = Provider<
  ({String firstName, String lastName, String username, String email})
>((ref) {
  final profile = ref.watch(
    profileControllerProvider.select((state) => state.profile),
  );
  if (profile != null) {
    return (
      firstName: profile.firstName,
      lastName: profile.lastName,
      username: profile.username,
      email: profile.email,
    );
  }
  return (
    firstName:
        ref.watch(authControllerProvider.select((s) => s.user?.firstName)) ??
        '',
    lastName:
        ref.watch(authControllerProvider.select((s) => s.user?.lastName)) ??
        '',
    username:
        ref.watch(authControllerProvider.select((s) => s.user?.username)) ??
        '',
    email:
        ref.watch(authControllerProvider.select((s) => s.user?.email)) ?? '',
  );
});

enum ProfileLoadStatus { loading, loaded, error }

class ProfileState {
  const ProfileState({
    this.status = ProfileLoadStatus.loading,
    this.profile,
    this.loadError,
    this.isSaving = false,
    this.saveError,
    this.isUploadingPicture = false,
    this.pictureError,
  });

  final ProfileLoadStatus status;
  final Profile? profile;
  final String? loadError;
  final bool isSaving;
  final String? saveError;
  final bool isUploadingPicture;
  final String? pictureError;

  /// The one real trigger for the post-login setup gate — `AuthGate` reads
  /// this once the profile has actually loaded.
  bool get needsOnboarding =>
      status == ProfileLoadStatus.loaded &&
      profile?.onboardingCompleted == false;

  ProfileState copyWith({
    ProfileLoadStatus? status,
    Profile? profile,
    String? loadError,
    bool clearLoadError = false,
    bool? isSaving,
    String? saveError,
    bool clearSaveError = false,
    bool? isUploadingPicture,
    String? pictureError,
    bool clearPictureError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      isSaving: isSaving ?? this.isSaving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      isUploadingPicture: isUploadingPicture ?? this.isUploadingPicture,
      pictureError: clearPictureError
          ? null
          : (pictureError ?? this.pictureError),
    );
  }
}

/// Coordinates the real, backend-authoritative profile: initial load,
/// field updates, and profile-picture upload. Every write updates local
/// state from the server's own response rather than assuming success.
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository, this._userId)
    : super(const ProfileState()) {
    _load();
  }

  final ProfileRepository _repository;
  final String _userId;

  /// The `profilePictureUrl` a refresh has already been attempted for —
  /// guards [refreshIfPictureUrlStale] against retrying the same expired
  /// signed URL over and over (e.g. if several widgets showing the same
  /// avatar all report the failure around the same time, or the freshly
  /// refreshed URL fails again with no network available).
  String? _lastPictureRefreshAttemptFor;

  /// Guards the one automatic retry in [_load] — reset to `false` on every
  /// successful load, so a *later*, genuinely new failure still gets its
  /// own single retry, but the same failure is never retried more than
  /// once. This is what actually keeps identity data (name/username/
  /// email) from getting stuck missing after a transient hiccup right
  /// after registering/logging in — previously the only way to recover
  /// was an unrelated mutation (e.g. a profile-picture upload) happening
  /// to overwrite [ProfileState.profile] with a fresh, successful
  /// response.
  bool _hasRetriedLoad = false;

  Future<void> _load({bool isRetry = false}) async {
    state = state.copyWith(
      status: ProfileLoadStatus.loading,
      clearLoadError: true,
    );
    try {
      final profile = await _repository.getProfile();
      if (kDebugMode) {
        debugPrint(
          '[ProfileController] loaded profile, '
          'profilePictureUrl=${profile.profilePictureUrl}',
        );
      }
      state = state.copyWith(
        status: ProfileLoadStatus.loaded,
        profile: profile,
      );
      _hasRetriedLoad = false;
    } catch (error) {
      // Not narrowed to `ApiException` — a malformed/unexpected response
      // (e.g. `Profile.fromJson` failing to parse a field) must also
      // resolve `status` deterministically to `error` rather than leaving
      // it stuck at `loading` forever with no way for the UI to recover.
      if (!isRetry && !_hasRetriedLoad) {
        _hasRetriedLoad = true;
        await _load(isRetry: true);
        return;
      }
      state = state.copyWith(
        status: ProfileLoadStatus.error,
        loadError: error is ApiException
            ? error.message
            : "Couldn't load your profile. Please try again.",
      );
    }
  }

  Future<void> refresh() => _load();

  /// Called when a displayed `profilePictureUrl` fails to load — most
  /// likely because its backend-issued signed URL has expired. Refreshes
  /// the profile (obtaining a fresh signed URL) at most once per distinct
  /// failing URL; a second failure for the same URL — including one that
  /// persists after this refresh, e.g. because the device has no network —
  /// is left alone rather than retried, so this can never become a loop.
  Future<void> refreshIfPictureUrlStale(String failedUrl) async {
    if (_lastPictureRefreshAttemptFor == failedUrl) return;
    _lastPictureRefreshAttemptFor = failedUrl;
    if (state.profile?.profilePictureUrl != failedUrl) return;
    await refresh();
  }

  /// Returns true on success. [changes] uses real backend field names
  /// (e.g. `first_name`, `income_frequency`) — callers build this from
  /// whichever form fields they're editing.
  Future<bool> updateProfile(Map<String, dynamic> changes) async {
    state = state.copyWith(isSaving: true, clearSaveError: true);
    try {
      final profile = await _repository.updateProfile(changes);
      state = state.copyWith(isSaving: false, profile: profile);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSaving: false, saveError: e.message);
      return false;
    }
  }

  Future<bool> uploadProfilePicture(File file) async {
    state = state.copyWith(isUploadingPicture: true, clearPictureError: true);
    try {
      final profile = await _repository.uploadProfilePicture(file);
      if (kDebugMode) {
        debugPrint(
          '[ProfileController] upload succeeded, '
          'profilePictureUrl=${profile.profilePictureUrl}',
        );
      }
      state = state.copyWith(isUploadingPicture: false, profile: profile);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isUploadingPicture: false,
        pictureError: e.message,
      );
      return false;
    } catch (e) {
      // Not just `ApiException` — a response the client can't parse (e.g.
      // an unexpected shape) must still resolve to a visible error rather
      // than an unhandled Future exception that silently leaves `state`
      // (and thus the displayed picture) exactly as it was before the
      // upload, with nothing telling the caller it failed.
      if (kDebugMode) {
        debugPrint('[ProfileController] upload failed to parse: $e');
      }
      state = state.copyWith(
        isUploadingPicture: false,
        pictureError: "Couldn't update your profile picture. Please try again.",
      );
      return false;
    }
  }

  void dismissSaveError() => state = state.copyWith(clearSaveError: true);

  void dismissPictureError() => state = state.copyWith(clearPictureError: true);

  String get userId => _userId;
}
