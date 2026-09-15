import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';

const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding, String? token) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      if (call.method == 'read' && call.arguments['key'] == 'access_token') {
        return token;
      }
      return null;
    },
  );
}

ApiClient _client(http.Client httpClient) {
  return ApiClient(baseUrl: 'http://test', client: httpClient);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding, 'token-123');
  });

  test('a successful GET decodes the JSON body', () async {
    final httpClient = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer token-123');
      expect(request.url.path, '/api/profile');
      return http.Response(jsonEncode({'id': 1}), 200);
    });

    final result = await _client(httpClient).get('/api/profile');

    expect(result, {'id': 1});
  });

  test(
    'no stored token throws ApiUnauthorizedException without a network call',
    () async {
      _mockSecureStorage(binding, null);
      var requested = false;
      final httpClient = MockClient((request) async {
        requested = true;
        return http.Response('{}', 200);
      });

      expect(
        _client(httpClient).get('/api/profile'),
        throwsA(isA<ApiUnauthorizedException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(requested, isFalse);
    },
  );

  test('a 401 response throws ApiUnauthorizedException', () async {
    final httpClient = MockClient(
      (request) async =>
          http.Response(jsonEncode({'error': 'unauthorized'}), 401),
    );

    expect(
      _client(httpClient).get('/api/profile'),
      throwsA(isA<ApiUnauthorizedException>()),
    );
  });

  test(
    'a flat {"error": "..."} body is parsed into the exception message',
    () async {
      final httpClient = MockClient(
        (request) async =>
            http.Response(jsonEncode({'error': 'No file provided'}), 400),
      );

      await expectLater(
        _client(httpClient).get('/api/files'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'No file provided',
          ),
        ),
      );
    },
  );

  test(
    'a structured {"error": {"code","message","details"}} body is parsed correctly',
    () async {
      final httpClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': "'XXX' is not a supported currency code.",
              'details': {'currency': 'unsupported currency'},
            },
          }),
          400,
        ),
      );

      await expectLater(
        _client(httpClient).patch('/api/preferences', {'currency': 'XXX'}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having(
                (e) => e.message,
                'message',
                "'XXX' is not a supported currency code.",
              )
              .having((e) => e.details, 'details', {
                'currency': 'unsupported currency',
              }),
        ),
      );
    },
  );

  test('a 404 throws ApiNotFoundException', () async {
    final httpClient = MockClient(
      (request) async =>
          http.Response(jsonEncode({'error': 'Notification not found'}), 404),
    );

    expect(
      _client(httpClient).get('/api/notifications/999'),
      throwsA(isA<ApiNotFoundException>()),
    );
  });

  test('a network failure surfaces a clear connection error', () async {
    final httpClient = MockClient(
      (request) async => throw Exception('socket closed'),
    );

    expect(
      _client(httpClient).get('/api/profile'),
      throwsA(isA<ApiException>()),
    );
  });

  test('PATCH sends a JSON-encoded body with the auth header', () async {
    final httpClient = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(jsonDecode(request.body), {'currency': 'USD'});
      expect(
        request.headers['Content-Type'],
        'application/json; charset=utf-8',
      );
      return http.Response(jsonEncode({'currency': 'USD'}), 200);
    });

    final result = await _client(
      httpClient,
    ).patch('/api/preferences', {'currency': 'USD'});

    expect(result, {'currency': 'USD'});
  });

  test('DELETE succeeds with an empty response body', () async {
    final httpClient = MockClient((request) async {
      expect(request.method, 'DELETE');
      return http.Response('', 200);
    });

    await _client(httpClient).delete('/api/goals/1');
  });

  test('uploadMultipart sends the explicit contentType, not the http package '
      'default of application/octet-stream', () async {
    final tempFile = File('${Directory.systemTemp.path}/upload_test.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final httpClient = MockClient.streaming((request, bodyStream) async {
      final multipart = request as http.MultipartRequest;
      expect(multipart.files.single.contentType.toString(), 'image/jpeg');
      return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
    });

    await _client(httpClient).uploadMultipart(
      '/api/profile/picture',
      fieldName: 'file',
      file: tempFile,
      contentType: 'image/jpeg',
    );
  });

  test('uploadMultipart without an explicit contentType falls back to the '
      'http package default', () async {
    final tempFile = File('${Directory.systemTemp.path}/upload_test2.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    addTearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    final httpClient = MockClient.streaming((request, bodyStream) async {
      final multipart = request as http.MultipartRequest;
      expect(
        multipart.files.single.contentType.toString(),
        'application/octet-stream',
      );
      return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
    });

    await _client(httpClient).uploadMultipart(
      '/api/profile/picture',
      fieldName: 'file',
      file: tempFile,
    );
  });
}
