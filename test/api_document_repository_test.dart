import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/profile/data/repositories/api_document_repository.dart';

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

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding);
  });

  ApiDocumentRepository repo(http.Client httpClient) {
    return ApiDocumentRepository(
      baseUrl: 'http://test',
      client: ApiClient(baseUrl: 'http://test', client: httpClient),
    );
  }

  test(
    'listFiles parses items and pagination, sending the page query',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/files');
        expect(request.url.queryParameters['page'], '2');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 9,
                'filename': 'August Statement.pdf',
                'size': 1024,
                'content_type': 'application/pdf',
                'document_type': 'bank_statement',
                'financial_period_start': null,
                'financial_period_end': null,
                'processing_status': 'pending',
                'created_at': '2026-01-01T10:00:00Z',
              },
            ],
            'pagination': {'page': 2, 'per_page': 20, 'total': 50},
          }),
          200,
        );
      });

      final page = await repo(client).listFiles(page: 2);

      expect(page.items, hasLength(1));
      expect(page.items.single.fileName, 'August Statement.pdf');
      expect(page.items.single.backendId, 9);
      expect(page.pagination.page, 2);
      expect(page.pagination.total, 50);
      expect(page.pagination.hasMore, isTrue);
    },
  );

  test('deleteFile sends a DELETE to the file endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/files/9');
      return http.Response(
        jsonEncode({'message': 'File deleted successfully'}),
        200,
      );
    });

    await repo(client).deleteFile(9);
  });

  test('a 404 throws ApiNotFoundException', () async {
    final client = MockClient(
      (request) async =>
          http.Response(jsonEncode({'error': 'File not found'}), 404),
    );

    expect(repo(client).deleteFile(999), throwsA(isA<ApiNotFoundException>()));
  });

  test(
    'getViewUrl calls GET /api/files/<id>/view and returns the signed url',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/files/9/view');
        return http.Response(
          jsonEncode({'url': 'https://pub-test.r2.dev/signed/9?exp=123'}),
          200,
        );
      });

      final url = await repo(client).getViewUrl(9);

      expect(url, 'https://pub-test.r2.dev/signed/9?exp=123');
    },
  );
}
