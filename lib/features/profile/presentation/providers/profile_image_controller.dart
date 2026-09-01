import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/local/profile_image_store.dart';
import '../../data/services/profile_image_picker_service.dart';

/// Swap for a fake in tests — the only thing in the profile feature that
/// talks to platform channels (photo library + permissions).
final profileImagePickerServiceProvider = Provider<ProfileImagePickerService>((
  ref,
) {
  return DeviceProfileImagePickerService();
});

final profileImageStoreProvider = Provider<ProfileImageStore>((ref) {
  return ProfileImageStore();
});

/// Rebuilt whenever the authenticated user changes, so one user's profile
/// picture never bleeds into another's session — same pattern as
/// `chatControllerProvider`.
final profileImageControllerProvider =
    StateNotifierProvider<ProfileImageController, ProfileImageState>((ref) {
      final userId =
          ref.watch(authControllerProvider.select((state) => state.user?.id)) ??
          'guest';
      return ProfileImageController(
        ref.watch(profileImagePickerServiceProvider),
        ref.watch(profileImageStoreProvider),
        userId,
      );
    });

class ProfileImageState {
  const ProfileImageState({
    this.imagePath,
    this.isLoading = false,
    this.isPicking = false,
    this.errorMessage,
    this.canOpenSettings = false,
  });

  /// On-device path of the persisted profile picture, or null if the user
  /// hasn't set one — callers fall back to the existing person icon.
  final String? imagePath;

  /// True while the initial persisted path is being loaded/verified.
  final bool isLoading;

  /// True while a pick is in progress (permission check + picker + copy).
  final bool isPicking;

  final String? errorMessage;

  /// Whether [errorMessage] should be paired with an "Open Settings"
  /// action (permanently-denied permission) rather than just "OK".
  final bool canOpenSettings;

  ProfileImageState copyWith({
    String? imagePath,
    bool clearImagePath = false,
    bool? isLoading,
    bool? isPicking,
    String? errorMessage,
    bool clearError = false,
    bool? canOpenSettings,
  }) {
    return ProfileImageState(
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      isLoading: isLoading ?? this.isLoading,
      isPicking: isPicking ?? this.isPicking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      canOpenSettings: clearError
          ? false
          : (canOpenSettings ?? this.canOpenSettings),
    );
  }
}

class ProfileImageController extends StateNotifier<ProfileImageState> {
  ProfileImageController(this._service, this._store, this._userId)
    : super(const ProfileImageState(isLoading: true)) {
    _load();
  }

  final ProfileImagePickerService _service;
  final ProfileImageStore _store;
  final String _userId;

  Future<void> _load() async {
    final path = await _store.loadImagePath(_userId);
    if (path == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    // Guards against a broken/missing image (e.g. cleared app storage) —
    // never show a broken image, just fall back to the default icon.
    final exists = await File(path).exists();
    state = state.copyWith(imagePath: exists ? path : null, isLoading: false);
  }

  Future<void> pickImage(ProfileImageSource source) async {
    if (state.isPicking) return;
    state = state.copyWith(isPicking: true, clearError: true);

    final result = await _service.pickAndPersistProfileImage(_userId, source);

    switch (result.outcome) {
      case ProfileImagePickOutcome.success:
        await _store.saveImagePath(_userId, result.filePath!);
        state = state.copyWith(
          imagePath: result.filePath,
          isPicking: false,
          clearError: true,
        );
      case ProfileImagePickOutcome.cancelled:
        state = state.copyWith(isPicking: false, clearError: true);
      case ProfileImagePickOutcome.permissionDenied:
        state = state.copyWith(
          isPicking: false,
          errorMessage: _permissionDeniedMessage(source),
          canOpenSettings: false,
        );
      case ProfileImagePickOutcome.permissionPermanentlyDenied:
        state = state.copyWith(
          isPicking: false,
          errorMessage: _permissionPermanentlyDeniedMessage(source),
          canOpenSettings: true,
        );
      case ProfileImagePickOutcome.invalidImage:
        state = state.copyWith(
          isPicking: false,
          errorMessage: "Couldn't use that image. Please try a different one.",
          canOpenSettings: false,
        );
    }
  }

  void dismissError() => state = state.copyWith(clearError: true);

  String _permissionDeniedMessage(ProfileImageSource source) {
    return source == ProfileImageSource.camera
        ? 'FinAssist needs camera access to take a profile photo.'
        : 'FinAssist needs access to your photos to choose a profile picture.';
  }

  String _permissionPermanentlyDeniedMessage(ProfileImageSource source) {
    final need = source == ProfileImageSource.camera
        ? 'FinAssist needs camera access to take a profile photo.'
        : 'FinAssist needs access to your photos to choose a profile picture.';
    return "$need You'll need to allow it from Settings.";
  }
}
