import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/profile/data/local/profile_image_store.dart';
import 'package:finassist/features/profile/data/services/profile_image_picker_service.dart';
import 'package:finassist/features/profile/presentation/providers/profile_image_controller.dart';

/// `flutter_secure_storage`'s MethodChannel doesn't exist in a test
/// environment — mock it with a simple in-memory map, same pattern used by
/// the chat feature's tests.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(
  TestWidgetsFlutterBinding binding,
  Map<String, String> values,
) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return values[call.arguments['key']];
        case 'write':
          values[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'delete':
          values.remove(call.arguments['key']);
          return null;
        default:
          return null;
      }
    },
  );
}

class _FakeProfileImagePickerService implements ProfileImagePickerService {
  ProfileImagePickResult nextResult = const ProfileImagePickResult.cancelled();

  @override
  Future<ProfileImagePickResult> pickAndPersistProfileImage(
    String userId,
    ProfileImageSource source,
  ) async {
    return nextResult;
  }
}

Future<void> _waitUntil(bool Function() condition, {int maxTries = 100}) async {
  for (var i = 0; i < maxTries; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, String> storageValues;

  setUp(() {
    storageValues = {};
    _mockSecureStorage(binding, storageValues);
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _secureStorageChannel,
      null,
    );
  });

  test('falls back to no image when nothing has been picked yet', () async {
    final controller = ProfileImageController(
      _FakeProfileImagePickerService(),
      ProfileImageStore(),
      'user-1',
    );

    await _waitUntil(() => !controller.state.isLoading);

    expect(controller.state.imagePath, isNull);
  });

  test('a successfully picked image is saved and reflected in state', () async {
    final tempFile = await File(
      '${Directory.systemTemp.path}/profile_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ).create();
    addTearDown(() => tempFile.delete());

    final service = _FakeProfileImagePickerService()
      ..nextResult = ProfileImagePickResult.success(tempFile.path);
    final controller = ProfileImageController(
      service,
      ProfileImageStore(),
      'user-1',
    );
    await _waitUntil(() => !controller.state.isLoading);

    await controller.pickImage(ProfileImageSource.gallery);

    expect(controller.state.imagePath, tempFile.path);
    expect(controller.state.errorMessage, isNull);
  });

  test('the picked image path persists across a simulated app restart', () async {
    final tempFile = await File(
      '${Directory.systemTemp.path}/profile_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ).create();
    addTearDown(() => tempFile.delete());

    final service = _FakeProfileImagePickerService()
      ..nextResult = ProfileImagePickResult.success(tempFile.path);
    final firstController = ProfileImageController(
      service,
      ProfileImageStore(),
      'user-1',
    );
    await _waitUntil(() => !firstController.state.isLoading);
    await firstController.pickImage(ProfileImageSource.gallery);
    expect(firstController.state.imagePath, tempFile.path);

    // A fresh controller instance (e.g. after relaunching the app) reads
    // from the same underlying secure-storage-backed store.
    final restartedController = ProfileImageController(
      _FakeProfileImagePickerService(),
      ProfileImageStore(),
      'user-1',
    );
    await _waitUntil(() => !restartedController.state.isLoading);

    expect(restartedController.state.imagePath, tempFile.path);
  });

  test('falls back to no image if the persisted file no longer exists', () async {
    final missingPath =
        '${Directory.systemTemp.path}/does_not_exist_${DateTime.now().microsecondsSinceEpoch}.jpg';
    await ProfileImageStore().saveImagePath('user-1', missingPath);

    final controller = ProfileImageController(
      _FakeProfileImagePickerService(),
      ProfileImageStore(),
      'user-1',
    );
    await _waitUntil(() => !controller.state.isLoading);

    expect(controller.state.imagePath, isNull);
  });

  test('a different user never sees the first user\'s profile picture', () async {
    final tempFile = await File(
      '${Directory.systemTemp.path}/profile_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    ).create();
    addTearDown(() => tempFile.delete());

    final service = _FakeProfileImagePickerService()
      ..nextResult = ProfileImagePickResult.success(tempFile.path);
    final userOne = ProfileImageController(
      service,
      ProfileImageStore(),
      'user-1',
    );
    await _waitUntil(() => !userOne.state.isLoading);
    await userOne.pickImage(ProfileImageSource.gallery);
    expect(userOne.state.imagePath, tempFile.path);

    final userTwo = ProfileImageController(
      _FakeProfileImagePickerService(),
      ProfileImageStore(),
      'user-2',
    );
    await _waitUntil(() => !userTwo.state.isLoading);

    expect(userTwo.state.imagePath, isNull);
  });

  test(
    'a permanently denied permission surfaces a clear, actionable message',
    () async {
      final service = _FakeProfileImagePickerService()
        ..nextResult =
            const ProfileImagePickResult.permissionPermanentlyDenied();
      final controller = ProfileImageController(
        service,
        ProfileImageStore(),
        'user-1',
      );
      await _waitUntil(() => !controller.state.isLoading);

      await controller.pickImage(ProfileImageSource.gallery);

      expect(controller.state.imagePath, isNull);
      expect(controller.state.errorMessage, isNotNull);
      expect(controller.state.canOpenSettings, isTrue);
    },
  );

  test('cancelling the picker leaves state untouched, no error', () async {
    final controller = ProfileImageController(
      _FakeProfileImagePickerService(),
      ProfileImageStore(),
      'user-1',
    );
    await _waitUntil(() => !controller.state.isLoading);

    await controller.pickImage(ProfileImageSource.gallery);

    expect(controller.state.imagePath, isNull);
    expect(controller.state.errorMessage, isNull);
  });
}
