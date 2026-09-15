import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/subscriptions/data/repositories/api_subscription_repository.dart';

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

Map<String, dynamic> _subscriptionJson({
  int id = 1,
  String status = 'active',
}) => {
  'id': id,
  'user_id': 7,
  'name': 'Netflix',
  'amount': 7000.0,
  'currency': 'NGN',
  'frequency': 'monthly',
  'next_billing_date': '2026-10-15',
  'category': 'entertainment',
  'payment_method': 'debit_card',
  'website': 'https://netflix.com',
  'notes': 'Family plan',
  'status': status,
  'created_at': '2026-01-01T10:00:00Z',
  'updated_at': '2026-01-01T10:00:00Z',
  'cancelled_at': null,
};

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding);
  });

  ApiSubscriptionRepository repo(http.Client httpClient) {
    return ApiSubscriptionRepository(
      baseUrl: 'http://test',
      client: ApiClient(baseUrl: 'http://test', client: httpClient),
    );
  }

  test(
    'getSubscriptions parses a bare JSON array, not an {items: ...} wrapper',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/subscriptions');
        return http.Response(
          jsonEncode([_subscriptionJson(id: 1), _subscriptionJson(id: 2)]),
          200,
        );
      });

      final subscriptions = await repo(client).getSubscriptions();

      expect(subscriptions, hasLength(2));
      expect(subscriptions.first.name, 'Netflix');
      expect(subscriptions.first.id, 1);
    },
  );

  test('getSubscriptions parses an empty array as an empty list', () async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode([]), 200),
    );

    final subscriptions = await repo(client).getSubscriptions();

    expect(subscriptions, isEmpty);
  });

  test('createSubscription POSTs and parses the created object', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/subscriptions');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['name'], 'Netflix');
      return http.Response(jsonEncode(_subscriptionJson()), 201);
    });

    final created = await repo(client).createSubscription({
      'name': 'Netflix',
      'amount': 7000,
      'currency': 'NGN',
      'frequency': 'monthly',
      'next_billing_date': '2026-10-15',
    });

    expect(created.name, 'Netflix');
    expect(created.status.apiValue, 'active');
  });

  test('updateSubscription PATCHes the right id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/subscriptions/5');
      return http.Response(jsonEncode(_subscriptionJson(id: 5, status: 'paused')), 200);
    });

    final updated = await repo(client).updateSubscription(5, {'status': 'paused'});

    expect(updated.id, 5);
    expect(updated.status.apiValue, 'paused');
  });

  test('deleteSubscription DELETEs the right id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/subscriptions/9');
      return http.Response(jsonEncode({'message': 'Subscription deleted successfully'}), 200);
    });

    await repo(client).deleteSubscription(9);
  });

  test('a 404 throws ApiNotFoundException', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'error': {'code': 'NOT_FOUND', 'message': 'Subscription not found'},
        }),
        404,
      ),
    );

    expect(
      repo(client).getSubscription(999),
      throwsA(isA<ApiNotFoundException>()),
    );
  });
}
