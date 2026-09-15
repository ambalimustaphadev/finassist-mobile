import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/profile/data/repositories/api_profile_repository.dart';

const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async =>
        call.method == 'read' && call.arguments['key'] == 'access_token'
        ? 'token-123'
        : null,
  );
}

Map<String, dynamic> _profileJson({String? profilePictureUrl}) => {
  'id': 1,
  'username': 'mustapha',
  'first_name': 'Mustapha',
  'last_name': 'Ambali',
  'email': 'demo@finassist.com',
  'country': 'Nigeria',
  'currency': 'NGN',
  'occupation': 'Engineer',
  'employment_status': 'employed',
  'income': 500000.0,
  'income_frequency': 'monthly',
  'profile_picture_url': profilePictureUrl,
  'onboarding_completed': true,
  'created_at': '2026-01-01T10:00:00Z',
  'updated_at': '2026-01-01T10:00:00Z',
};

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding);
  });

  ApiProfileRepository repo(http.Client httpClient) {
    return ApiProfileRepository(
      baseUrl: 'http://test',
      client: ApiClient(baseUrl: 'http://test', client: httpClient),
    );
  }

  test('getProfile parses the real backend field names', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/profile');
      return http.Response(jsonEncode(_profileJson()), 200);
    });

    final profile = await repo(client).getProfile();

    expect(profile.id, 1);
    expect(profile.firstName, 'Mustapha');
    expect(profile.lastName, 'Ambali');
    expect(profile.fullName, 'Mustapha Ambali');
    expect(profile.currency, 'NGN');
    expect(profile.employmentStatus, 'employed');
    expect(profile.income, 500000.0);
    expect(profile.onboardingCompleted, isTrue);
  });

  test('updateProfile PATCHes only the given changes', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(jsonDecode(request.body), {'first_name': 'Ada'});
      return http.Response(
        jsonEncode({..._profileJson(), 'first_name': 'Ada'}),
        200,
      );
    });

    final profile = await repo(client).updateProfile({'first_name': 'Ada'});

    expect(profile.firstName, 'Ada');
  });

  test('a validation error surfaces the structured backend message', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': "'XX' is not a supported currency code.",
            'details': {'currency': 'unsupported currency'},
          },
        }),
        400,
      ),
    );

    await expectLater(
      repo(client).updateProfile({'currency': 'XX'}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          "'XX' is not a supported currency code.",
        ),
      ),
    );
  });

  test('uploadProfilePicture sends a multipart request and returns the '
      'updated profile', () async {
    final tempFile = File('${Directory.systemTemp.path}/avatar_test.jpg')
      ..writeAsBytesSync(_jpegBytes);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final client = MockClient.streaming((request, bodyStream) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/profile/picture');
      expect(request, isA<http.MultipartRequest>());
      final multipart = request as http.MultipartRequest;
      expect(multipart.files.single.field, 'file');
      expect(multipart.files.single.contentType.mimeType, 'image/jpeg');
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode(
              _profileJson(
                profilePictureUrl:
                    'https://pub-test.r2.dev/profile-pictures/1/uuid.jpg',
              ),
            ),
          ),
        ),
        200,
      );
    });

    final profile = await repo(client).uploadProfilePicture(tempFile);

    expect(
      profile.profilePictureUrl,
      'https://pub-test.r2.dev/profile-pictures/1/uuid.jpg',
    );
  });

  test('uploadProfilePicture accepts a .jpg-named JPEG', () async {
    final tempFile = File('${Directory.systemTemp.path}/avatar_test_2.jpg')
      ..writeAsBytesSync(_jpegBytes);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final client = MockClient.streaming((request, bodyStream) async {
      final multipart = request as http.MultipartRequest;
      expect(multipart.files.single.contentType.mimeType, 'image/jpeg');
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(_profileJson()))),
        200,
      );
    });

    await repo(client).uploadProfilePicture(tempFile);
  });

  test('uploadProfilePicture accepts a .jpeg-named JPEG', () async {
    final tempFile = File('${Directory.systemTemp.path}/avatar_test_3.jpeg')
      ..writeAsBytesSync(_jpegBytes);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final client = MockClient.streaming((request, bodyStream) async {
      final multipart = request as http.MultipartRequest;
      expect(multipart.files.single.contentType.mimeType, 'image/jpeg');
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(_profileJson()))),
        200,
      );
    });

    await repo(client).uploadProfilePicture(tempFile);
  });

  test('uploadProfilePicture accepts a PNG', () async {
    final tempFile = File('${Directory.systemTemp.path}/avatar_test.png')
      ..writeAsBytesSync(_pngBytes);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final client = MockClient.streaming((request, bodyStream) async {
      final multipart = request as http.MultipartRequest;
      expect(multipart.files.single.contentType.mimeType, 'image/png');
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(_profileJson()))),
        200,
      );
    });

    await repo(client).uploadProfilePicture(tempFile);
  });

  test('uploadProfilePicture accepts a WEBP', () async {
    final tempFile = File('${Directory.systemTemp.path}/avatar_test.webp')
      ..writeAsBytesSync(_webpBytes);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final client = MockClient.streaming((request, bodyStream) async {
      final multipart = request as http.MultipartRequest;
      expect(multipart.files.single.contentType.mimeType, 'image/webp');
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(_profileJson()))),
        200,
      );
    });

    await repo(client).uploadProfilePicture(tempFile);
  });

  test(
    'uploadProfilePicture accepts a real JPEG even without a recognized '
    'extension (missing/odd extension metadata must not block a valid image)',
    () async {
      final tempFile = File('${Directory.systemTemp.path}/avatar_test_noext')
        ..writeAsBytesSync(_jpegBytes);
      addTearDown(() {
        if (tempFile.existsSync()) tempFile.deleteSync();
      });

      final client = MockClient.streaming((request, bodyStream) async {
        final multipart = request as http.MultipartRequest;
        expect(multipart.files.single.contentType.mimeType, 'image/jpeg');
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(_profileJson()))),
          200,
        );
      });

      await repo(client).uploadProfilePicture(tempFile);
    },
  );

  test('uploadProfilePicture rejects an unsupported file without calling the '
      'network, and surfaces the friendly message', () async {
    final tempFile = File('${Directory.systemTemp.path}/not_an_image.jpg')
      ..writeAsBytesSync([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    var requested = false;
    final client = MockClient.streaming((request, bodyStream) async {
      requested = true;
      return http.StreamedResponse(const Stream.empty(), 200);
    });

    await expectLater(
      repo(client).uploadProfilePicture(tempFile),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Profile image must be JPEG, PNG, or WEBP.',
        ),
      ),
    );
    expect(requested, isFalse);
  });
}

/// Minimal but real magic-number-valid bytes for each supported format —
/// enough for `package:mime`'s content sniffing to recognize the real type,
/// without needing a full decodable image.
final _jpegBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46];
final _pngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D,
];
final _webpBytes = [
  0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, //
  0x57, 0x45, 0x42, 0x50,
];
