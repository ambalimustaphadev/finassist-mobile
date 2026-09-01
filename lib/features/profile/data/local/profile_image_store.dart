import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the on-device file path of the user's chosen profile picture,
/// keyed per user so switching accounts on the same device never shows one
/// user's photo to another. Mirrors `LocalConversationStore`'s pattern of
/// using `flutter_secure_storage` (already a dependency) for small local
/// records rather than adding another storage package.
///
/// The image bytes themselves live in the app's documents directory (see
/// `DeviceProfileImagePickerService`); this store only remembers where to
/// find them.
class ProfileImageStore {
  ProfileImageStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String userId) => 'profile_image_path_v1_$userId';

  Future<String?> loadImagePath(String userId) {
    return _storage.read(key: _key(userId));
  }

  Future<void> saveImagePath(String userId, String path) {
    return _storage.write(key: _key(userId), value: path);
  }

  Future<void> clearImagePath(String userId) {
    return _storage.delete(key: _key(userId));
  }
}
