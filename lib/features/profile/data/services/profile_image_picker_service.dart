import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Where the user chose to source a profile picture from — mirrors the
/// three options on the picker's action sheet.
enum ProfileImageSource { gallery, camera, file }

/// How a profile-picture pick attempt concluded.
enum ProfileImagePickOutcome {
  success,
  cancelled,
  permissionDenied,

  /// The user (or a previous prompt) denied photo access permanently —
  /// asking again through the OS dialog won't work; the only way forward
  /// is the system Settings app.
  permissionPermanentlyDenied,
  invalidImage,
}

class ProfileImagePickResult {
  const ProfileImagePickResult._(this.outcome, this.filePath);

  const ProfileImagePickResult.success(String filePath)
    : this._(ProfileImagePickOutcome.success, filePath);

  const ProfileImagePickResult.cancelled()
    : this._(ProfileImagePickOutcome.cancelled, null);

  const ProfileImagePickResult.permissionDenied()
    : this._(ProfileImagePickOutcome.permissionDenied, null);

  const ProfileImagePickResult.permissionPermanentlyDenied()
    : this._(ProfileImagePickOutcome.permissionPermanentlyDenied, null);

  const ProfileImagePickResult.invalidImage()
    : this._(ProfileImagePickOutcome.invalidImage, null);

  final ProfileImagePickOutcome outcome;

  /// The persisted, on-device path of the copied image — set only when
  /// [outcome] is [ProfileImagePickOutcome.success].
  final String? filePath;
}

/// Lets the user pick a profile picture from their device. A real
/// implementation wraps `image_picker`/`file_picker`/`permission_handler`;
/// tests can substitute a fake that returns a canned result without
/// touching platform channels — mirrors `StatementFilePickerService`'s
/// seam.
abstract class ProfileImagePickerService {
  Future<ProfileImagePickResult> pickAndPersistProfileImage(
    String userId,
    ProfileImageSource source,
  );
}

class DeviceProfileImagePickerService implements ProfileImagePickerService {
  DeviceProfileImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ProfileImagePickResult> pickAndPersistProfileImage(
    String userId,
    ProfileImageSource source,
  ) async {
    switch (source) {
      case ProfileImageSource.file:
        return _pickFromFileSystem(userId);
      case ProfileImageSource.gallery:
        return _pickFromGallery(userId);
      case ProfileImageSource.camera:
        return _pickFromCamera(userId);
    }
  }

  /// The modern system photo picker (`PHPickerViewController` on iOS 14+;
  /// the Android Photo Picker on Android 13+, or a permission-less
  /// content picker on older Android) runs out-of-process and only ever
  /// hands the app the one photo the user chose — it was never granted,
  /// and doesn't need, any app-level photo-library permission. Checking
  /// `permission_handler` here was the bug: it asked for a *different*,
  /// broader permission the picker itself never requires, so a fresh
  /// install always looked "denied" before the native picker ever had a
  /// chance to run.
  Future<ProfileImagePickResult> _pickFromGallery(String userId) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (_) {
      return const ProfileImagePickResult.invalidImage();
    }
    if (picked == null) return const ProfileImagePickResult.cancelled();
    return _persist(picked.path, userId);
  }

  /// Unlike the gallery, taking a photo genuinely requires camera access
  /// on both platforms, so this is the only source that still consults
  /// `permission_handler` — and only to decide *when* to show a
  /// "permanently denied" Settings prompt instead of attempting to launch
  /// the camera. The actual permission request itself happens right here,
  /// at the moment the user chose "Take photo", so the real system prompt
  /// appears immediately rather than the app pre-emptively asking earlier.
  Future<ProfileImagePickResult> _pickFromCamera(String userId) async {
    PermissionStatus status;
    try {
      status = await Permission.camera.status;
    } catch (_) {
      // The permission plugin has nothing meaningful to report on this
      // platform (e.g. desktop) — let the OS-level picker itself handle
      // permissioning rather than blocking the flow.
      return _launchCamera(userId);
    }

    if (status.isGranted || status.isLimited) return _launchCamera(userId);
    if (status.isPermanentlyDenied) {
      return const ProfileImagePickResult.permissionPermanentlyDenied();
    }

    // Not yet determined, or a prior denial the OS still allows asking
    // again for — either way, this is a genuine first (or retried)
    // request, never an assumption of permanent denial.
    status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return _launchCamera(userId);
    if (status.isPermanentlyDenied) {
      return const ProfileImagePickResult.permissionPermanentlyDenied();
    }
    return const ProfileImagePickResult.permissionDenied();
  }

  Future<ProfileImagePickResult> _launchCamera(String userId) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (_) {
      return const ProfileImagePickResult.invalidImage();
    }
    if (picked == null) return const ProfileImagePickResult.cancelled();
    return _persist(picked.path, userId);
  }

  /// The native document/file picker (`file_picker`) — unlike the photo
  /// library or camera, this doesn't need a `permission_handler` check: on
  /// both iOS and Android it's backed by a system picker (Files app /
  /// Storage Access Framework) that handles its own access grant per file,
  /// the same way `FilePickerStatementService` already picks statements
  /// without requesting any runtime permission.
  Future<ProfileImagePickResult> _pickFromFileSystem(String userId) async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } catch (_) {
      return const ProfileImagePickResult.invalidImage();
    }
    final files = result?.files ?? const [];
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return const ProfileImagePickResult.cancelled();
    return _persist(path, userId);
  }

  Future<ProfileImagePickResult> _persist(
    String sourcePath,
    String userId,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return const ProfileImagePickResult.invalidImage();
      }

      final directory = await getApplicationDocumentsDirectory();
      await _removePreviousImages(directory, userId);

      final extension = _extensionOf(sourcePath);
      final destinationPath = '${directory.path}/profile_$userId$extension';
      final savedFile = await sourceFile.copy(destinationPath);

      return ProfileImagePickResult.success(savedFile.path);
    } catch (_) {
      return const ProfileImagePickResult.invalidImage();
    }
  }

  Future<void> _removePreviousImages(Directory directory, String userId) async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.contains('${Platform.pathSeparator}profile_$userId.')) {
        await entity.delete();
      }
    }
  }

  String _extensionOf(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return '.jpg';
    return path.substring(dotIndex);
  }
}
