import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/activity/data/repositories/api_activity_log_repository.dart';

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

  ApiActivityLogRepository repo(http.Client httpClient) {
    return ApiActivityLogRepository(
      baseUrl: 'http://test',
      client: ApiClient(baseUrl: 'http://test', client: httpClient),
    );
  }

  test('getActivity parses the items list', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/activity');
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 1,
              'type': 'goal_created',
              'title': "Goal 'Vacation fund' created",
              'description': null,
              'metadata': {'goal_id': 3},
              'created_at': '2026-01-01T10:00:00Z',
              'read_at': null,
            },
          ],
          'pagination': {'page': 1, 'per_page': 20, 'total': 1},
        }),
        200,
      );
    });

    final entries = await repo(client).getActivity();

    expect(entries, hasLength(1));
    expect(entries.single.type, 'goal_created');
    expect(entries.single.description, isNull);
  });

  test('logActivity POSTs the type/title/description', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/activity');
      expect(jsonDecode(request.body), {
        'type': 'loan_calculation',
        'title': 'Loan Calculator',
        'description': '₦1,200,000 over 12 months at 0% → ₦100,000/month',
      });
      return http.Response(
        jsonEncode({
          'id': 5,
          'type': 'loan_calculation',
          'title': 'Loan Calculator',
          'description': '₦1,200,000 over 12 months at 0% → ₦100,000/month',
          'metadata': null,
          'created_at': '2026-01-01T10:00:00Z',
          'read_at': null,
        }),
        201,
        // Without an explicit Content-Type, `package:http` can't tell this
        // is JSON and falls back to latin1 for the body bytes, which
        // throws on non-Latin1 characters like ₦/→ — real Flask responses
        // always set this header, so this just matches that.
        headers: {'content-type': 'application/json'},
      );
    });

    await repo(client).logActivity(
      type: 'loan_calculation',
      title: 'Loan Calculator',
      description: '₦1,200,000 over 12 months at 0% → ₦100,000/month',
    );
  });

  test('a disallowed type surfaces the structured backend message', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': "'goal_created' is not a loggable activity type.",
          },
        }),
        400,
      ),
    );

    await expectLater(
      repo(client).logActivity(type: 'goal_created', title: 'x'),
      throwsA(isA<ApiException>()),
    );
  });
}
