import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/features/profile/data/repositories/api_file_upload_repository.dart';
import 'package:finassist/features/profile/data/repositories/file_upload_repository.dart';

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
        default:
          return null;
      }
    },
  );
}

ApiFileUploadRepository _repo(http.Client client) {
  return ApiFileUploadRepository(
    baseUrl: 'http://test',
    client: client,
    storage: const FlutterSecureStorage(),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _secureStorageChannel,
      null,
    );
  });

  Future<File> tempFile(String content) async {
    final file = File(
      '${Directory.systemTemp.path}/upload_test_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    return file.writeAsString(content);
  }

  test('sends a multipart POST to /api/files/upload with the bearer token and '
      'the "file" field, and parses the response', () async {
    _mockSecureStorage(binding, {'access_token': 'token-123'});
    final file = await tempFile('%PDF-1.4 fake statement bytes');
    addTearDown(() => file.delete());

    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/files/upload');
      expect(request.headers['Authorization'], 'Bearer token-123');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      // The multipart field must be exactly "file", and the body must
      // never be plain JSON.
      expect(request.body, contains('name="file"'));
      expect(request.body, isNot(contains('"filename"')));

      return http.Response(
        jsonEncode({
          'message': 'File uploaded successfully',
          'file': {
            'id': 1,
            'filename': 'statement.pdf',
            'size': 83318,
            'content_type': 'application/pdf',
            'key': 'statements/4/uuid.pdf',
          },
        }),
        201,
      );
    });

    final uploaded = await _repo(client).uploadFile(file);

    expect(uploaded.id, 1);
    expect(uploaded.filename, 'statement.pdf');
    expect(uploaded.size, 83318);
    expect(uploaded.contentType, 'application/pdf');
    expect(uploaded.key, 'statements/4/uuid.pdf');
  });

  test('401 throws FileUploadUnauthorizedException', () async {
    _mockSecureStorage(binding, {'access_token': 'expired'});
    final file = await tempFile('data');
    addTearDown(() => file.delete());

    final client = MockClient((request) async {
      return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
    });

    expect(
      _repo(client).uploadFile(file),
      throwsA(isA<FileUploadUnauthorizedException>()),
    );
  });

  test('no stored token throws FileUploadUnauthorizedException without a '
      'network call', () async {
    _mockSecureStorage(binding, {});
    final file = await tempFile('data');
    addTearDown(() => file.delete());
    var requested = false;
    final client = MockClient((request) async {
      requested = true;
      return http.Response('{}', 200);
    });

    await expectLater(
      _repo(client).uploadFile(file),
      throwsA(isA<FileUploadUnauthorizedException>()),
    );
    expect(requested, isFalse);
  });

  test('a non-2xx server error throws a clear exception', () async {
    _mockSecureStorage(binding, {'access_token': 'token-123'});
    final file = await tempFile('data');
    addTearDown(() => file.delete());

    final client = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    expect(_repo(client).uploadFile(file), throwsException);
  });

  test('network failure throws a clear connection error', () async {
    _mockSecureStorage(binding, {'access_token': 'token-123'});
    final file = await tempFile('data');
    addTearDown(() => file.delete());

    final client = MockClient((request) async {
      throw Exception('socket closed');
    });

    expect(_repo(client).uploadFile(file), throwsException);
  });

  test('a missing file throws a friendly exception, not a raw error', () async {
    _mockSecureStorage(binding, {'access_token': 'token-123'});
    final missing = File(
      '${Directory.systemTemp.path}/does_not_exist_${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    var requested = false;
    final client = MockClient((request) async {
      requested = true;
      return http.Response('{}', 200);
    });

    await expectLater(_repo(client).uploadFile(missing), throwsException);
    expect(requested, isFalse);
  });
}
