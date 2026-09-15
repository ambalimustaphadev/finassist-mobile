import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/notifications/data/repositories/api_notification_repository.dart';

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

  ApiNotificationRepository repo(http.Client httpClient) {
    return ApiNotificationRepository(
      baseUrl: 'http://test',
      client: ApiClient(baseUrl: 'http://test', client: httpClient),
    );
  }

  test(
    'getNotifications parses an empty list as empty, not an error',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/notifications');
        return http.Response(
          jsonEncode({
            'items': [],
            'pagination': {'page': 1, 'per_page': 20, 'total': 0},
          }),
          200,
        );
      });

      final page = await repo(client).getNotifications();

      expect(page.items, isEmpty);
    },
  );

  test('getNotifications parses real items', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'items': [
            {
              'id': 1,
              'type': 'goal_approaching_deadline',
              'title': 'Vacation fund deadline is approaching',
              'body': null,
              'read': false,
              'metadata': {'goal_id': 3},
              'created_at': '2026-01-01T10:00:00Z',
            },
          ],
          'pagination': {'page': 1, 'per_page': 20, 'total': 1},
        }),
        200,
      ),
    );

    final page = await repo(client).getNotifications();

    expect(page.items.single.title, 'Vacation fund deadline is approaching');
    expect(page.items.single.read, isFalse);
  });

  test('markRead PATCHes the notification endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/notifications/5');
      return http.Response(
        jsonEncode({
          'id': 5,
          'type': 'x',
          'title': 'x',
          'body': null,
          'read': true,
          'metadata': null,
          'created_at': '2026-01-01T10:00:00Z',
        }),
        200,
      );
    });

    await repo(client).markRead(5);
  });

  test('markAllRead PATCHes the read-all endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/notifications/read-all');
      return http.Response(
        jsonEncode({'message': 'All notifications marked as read'}),
        200,
      );
    });

    await repo(client).markAllRead();
  });

  test('a 404 throws ApiNotFoundException', () async {
    final client = MockClient(
      (request) async =>
          http.Response(jsonEncode({'error': 'Notification not found'}), 404),
    );

    expect(repo(client).markRead(999), throwsA(isA<ApiNotFoundException>()));
  });
}
