import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/features/auth/data/repositories/api_auth_repository.dart';
import 'package:finassist/features/auth/data/repositories/auth_repository.dart';

/// Covers the startup/offline fix: a stored token must never force the
/// whole app behind a global "couldn't connect" gate. `restoreSession()`
/// should resolve locally (no network call) when there's no token, and
/// fall back to a cached user rather than [SessionRestoreOutcome.unavailable]
/// when the backend can't be reached to verify an existing one.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(
  TestWidgetsFlutterBinding binding,
  Map<String, String> initialValues,
) {
  final values = Map<String, String>.from(initialValues);
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

ApiAuthRepository _repo(http.Client client) {
  return ApiAuthRepository(baseUrl: 'http://test', client: client);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'no stored token resolves to noSession without any network call',
    () async {
      _mockSecureStorage(binding, {});
      var requested = false;
      final repo = _repo(
        MockClient((request) async {
          requested = true;
          return http.Response('{}', 200);
        }),
      );

      final result = await repo.restoreSession();

      expect(result.outcome, SessionRestoreOutcome.noSession);
      expect(requested, isFalse);
    },
  );

  test(
    'a reachable backend resolving /api/me resolves authenticated and caches the user',
    () async {
      _mockSecureStorage(binding, {
        'access_token': 'token-1',
        'refresh_token': 'refresh-1',
      });
      final repo = _repo(
        MockClient((request) async {
          expect(request.url.path, '/api/me');
          return http.Response(
            jsonEncode({
              'user': {
                'id': '1',
                'first_name': 'Ada',
                'last_name': 'Lovelace',
                'email': 'ada@finassist.com',
                'username': 'ada',
              },
            }),
            200,
          );
        }),
      );

      final result = await repo.restoreSession();

      expect(result.outcome, SessionRestoreOutcome.authenticated);
      expect(result.user!.firstName, 'Ada');
    },
  );

  test('a stored token + unreachable backend resolves authenticated from the '
      'cached user rather than the global unavailable gate', () async {
    _mockSecureStorage(binding, {
      'access_token': 'token-1',
      'refresh_token': 'refresh-1',
      'cached_user_v1': jsonEncode({
        'id': '1',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'email': 'ada@finassist.com',
        'username': 'ada',
      }),
    });
    final repo = _repo(
      MockClient((request) async => throw Exception('connection refused')),
    );

    final result = await repo.restoreSession();

    expect(result.outcome, SessionRestoreOutcome.authenticated);
    expect(result.user!.firstName, 'Ada');
  });

  test('a stored token + unreachable backend + no cached user falls back to '
      'unavailable, and never clears the stored token', () async {
    _mockSecureStorage(binding, {
      'access_token': 'token-1',
      'refresh_token': 'refresh-1',
    });
    final repo = _repo(
      MockClient((request) async => throw Exception('connection refused')),
    );

    final result = await repo.restoreSession();

    expect(result.outcome, SessionRestoreOutcome.unavailable);
    expect(await repo.getAccessToken(), 'token-1');
  });

  test('an ambiguous 5xx response resolves authenticated from the cached user '
      'instead of unavailable', () async {
    _mockSecureStorage(binding, {
      'access_token': 'token-1',
      'refresh_token': 'refresh-1',
      'cached_user_v1': jsonEncode({
        'id': '1',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'email': 'ada@finassist.com',
        'username': 'ada',
      }),
    });
    final repo = _repo(
      MockClient((request) async => http.Response('Server error', 503)),
    );

    final result = await repo.restoreSession();

    expect(result.outcome, SessionRestoreOutcome.authenticated);
  });

  test('a definitive 401 with no valid refresh token clears the session '
      '(explicit rejection, not a network failure)', () async {
    _mockSecureStorage(binding, {
      'access_token': 'expired-token',
      'refresh_token': 'refresh-1',
      'cached_user_v1': jsonEncode({
        'id': '1',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'email': 'ada@finassist.com',
        'username': 'ada',
      }),
    });
    final repo = _repo(
      MockClient((request) async => http.Response('Unauthorized', 401)),
    );

    final result = await repo.restoreSession();

    expect(result.outcome, SessionRestoreOutcome.noSession);
    expect(await repo.getAccessToken(), isNull);
  });

  test(
    'a successful login caches the user for later optimistic restores',
    (() async {
      _mockSecureStorage(binding, {});
      final repo = _repo(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'access_token': 'token-1',
              'refresh_token': 'refresh-1',
              'user': {
                'id': '1',
                'first_name': 'Ada',
                'last_name': 'Lovelace',
                'email': 'ada@finassist.com',
                'username': 'ada',
              },
            }),
            200,
          );
        }),
      );

      await repo.login(email: 'ada@finassist.com', password: 'password123');

      // Simulate a relaunch with the backend now unreachable: the cache
      // written by login() should be enough to resolve authenticated.
      final offlineRepo = _repo(
        MockClient((request) async => throw Exception('connection refused')),
      );
      final result = await offlineRepo.restoreSession();

      expect(result.outcome, SessionRestoreOutcome.authenticated);
      expect(result.user!.firstName, 'Ada');
    }),
  );

  test('logout clears the token, refresh token, and cached user', () async {
    _mockSecureStorage(binding, {
      'access_token': 'token-1',
      'refresh_token': 'refresh-1',
      'cached_user_v1': jsonEncode({
        'id': '1',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'email': 'ada@finassist.com',
        'username': 'ada',
      }),
    });
    final repo = _repo(MockClient((request) async => http.Response('', 200)));

    await repo.logout();

    expect(await repo.getAccessToken(), isNull);
    // With no token left, a subsequent restore must resolve locally too.
    var requested = false;
    final repoAfterLogout = _repo(
      MockClient((request) async {
        requested = true;
        return http.Response('{}', 200);
      }),
    );
    final result = await repoAfterLogout.restoreSession();
    expect(result.outcome, SessionRestoreOutcome.noSession);
    expect(requested, isFalse);
  });
}
