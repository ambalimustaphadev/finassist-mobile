import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/profile/data/repositories/api_preference_repository.dart';

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

Map<String, dynamic> _preferencesJson({String currency = 'NGN'}) => {
  'currency': currency,
  'language': 'en',
  'notifications_enabled': true,
  'document_notifications': false,
  'updated_at': '2026-01-01T10:00:00Z',
};

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding);
  });

  ApiPreferenceRepository repo(http.Client httpClient) {
    return ApiPreferenceRepository(
      baseUrl: 'http://test',
      client: ApiClient(baseUrl: 'http://test', client: httpClient),
    );
  }

  test('getPreferences parses the real backend field names', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/preferences');
      return http.Response(jsonEncode(_preferencesJson()), 200);
    });

    final preferences = await repo(client).getPreferences();

    expect(preferences.currency, 'NGN');
    expect(preferences.language, 'en');
    expect(preferences.notificationsEnabled, isTrue);
    expect(preferences.documentNotifications, isFalse);
  });

  test('updatePreferences PATCHes only the given changes', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(jsonDecode(request.body), {'currency': 'USD'});
      return http.Response(jsonEncode(_preferencesJson(currency: 'USD')), 200);
    });

    final preferences = await repo(
      client,
    ).updatePreferences({'currency': 'USD'});

    expect(preferences.currency, 'USD');
  });

  test(
    'an unsupported currency surfaces the structured backend message',
    () async {
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
        repo(client).updatePreferences({'currency': 'XX'}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            "'XX' is not a supported currency code.",
          ),
        ),
      );
    },
  );
}
