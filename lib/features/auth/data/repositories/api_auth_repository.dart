import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../auth_exception.dart';
import '../models/auth_user.dart';
import '../models/register_request.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  /// The last-known authenticated user, cached locally on every successful
  /// `/api/me`/login response. Backs the optimistic-authentication path
  /// below: a stored token plus this cache is enough to resolve straight to
  /// the Dashboard while the backend is unreachable, rather than blocking
  /// the whole app behind a global "couldn't connect" gate — connectivity
  /// failures are then scoped to whichever screen actually requests data.
  static const _cachedUserKey = 'cached_user_v1';

  /// Session restoration must never hang the splash/auth-gate loading
  /// state indefinitely — an unreachable server surfaces as
  /// [SessionRestoreOutcome.unavailable] (or the optimistic cached-user
  /// path below) within this window instead.
  static const _restoreTimeout = Duration(seconds: 8);

  @override
  Future<SessionRestoreResult> restoreSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    // No stored session at all — go straight to Login. This never depends
    // on the backend being reachable.
    if (accessToken == null || refreshToken == null) {
      return const SessionRestoreResult.noSession();
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/me'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(_restoreTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
        await _cacheUser(user);
        return SessionRestoreResult.authenticated(user);
      }

      // Access token may have expired — try a refresh before giving up.
      if (response.statusCode == 401) {
        final newAccessToken = await _refreshAccessToken();

        if (newAccessToken == null) {
          await _clearTokens();
          return const SessionRestoreResult.noSession();
        }

        final retryResponse = await _client
            .get(
              Uri.parse('$baseUrl/api/me'),
              headers: {'Authorization': 'Bearer $newAccessToken'},
            )
            .timeout(_restoreTimeout);

        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body) as Map<String, dynamic>;
          final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
          await _cacheUser(user);
          return SessionRestoreResult.authenticated(user);
        }

        await _clearTokens();
        return const SessionRestoreResult.noSession();
      }

      // An ambiguous server-side error (5xx etc.) — the session may still
      // be valid, so don't wipe the stored tokens over what could be a
      // transient backend issue. Trust the locally cached session instead
      // of blocking the whole app behind a connection-error screen.
      return _optimisticFromCache();
    } on TimeoutException {
      return _optimisticFromCache();
    } catch (_) {
      return _optimisticFromCache();
    }
  }

  /// A stored token exists but the backend couldn't be reached (or gave an
  /// ambiguous error) to verify it. Rather than surface a global
  /// connection-error gate — indistinguishable, from the user's point of
  /// view, from being logged out — resolve as authenticated using the
  /// last-known user, deferring to whichever screen actually needs live
  /// data to show its own scoped "couldn't connect" state. Only falls back
  /// to [SessionRestoreOutcome.unavailable] if no user was ever cached
  /// (e.g. the very first restore after upgrading from a build that
  /// predates this cache).
  Future<SessionRestoreResult> _optimisticFromCache() async {
    final cachedUser = await _readCachedUser();
    if (cachedUser == null) return const SessionRestoreResult.unavailable();
    return SessionRestoreResult.authenticated(cachedUser);
  }

  Future<void> _cacheUser(AuthUser user) {
    return _storage.write(
      key: _cachedUserKey,
      value: jsonEncode({
        'id': user.id,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'email': user.email,
        'username': user.username,
      }),
    );
  }

  Future<AuthUser?> _readCachedUser() async {
    final raw = await _storage.read(key: _cachedUserKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    http.Response response;

    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_restoreTimeout);
    } catch (_) {
      throw const AuthException(
        "Can't reach the server right now. "
        "Check your connection and try again.",
      );
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const AuthException("That email or password doesn't look right.");
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AuthException('Something went wrong. Please try again.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    final userData = data['user'];

    if (accessToken == null || refreshToken == null || userData == null) {
      throw const AuthException(
        'The server returned an invalid login response.',
      );
    }

    await _storage.write(key: _accessTokenKey, value: accessToken.toString());

    await _storage.write(key: _refreshTokenKey, value: refreshToken.toString());

    final user = AuthUser.fromJson(userData as Map<String, dynamic>);
    await _cacheUser(user);
    return user;
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    final request = RegisterRequest(
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: username,
      password: password,
    );

    http.Response response;

    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_restoreTimeout);
    } catch (_) {
      throw const AuthException(
        "Can't reach the server right now. "
        "Check your connection and try again.",
      );
    }

    if (response.statusCode == 409) {
      throw const AuthException('That email or username is already taken.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  /// The actual refresh HTTP call/storage write, shared by both
  /// [_refreshAccessToken] (restoreSession's internal, network-errors-
  /// swallowed-to-null use) and the public [refreshAccessToken] (which
  /// lets a network/timeout failure propagate instead) — one mechanism,
  /// two error-mapping policies for two different callers, rather than
  /// two separate implementations of the same request.
  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/refresh'),
          headers: {'Authorization': 'Bearer $refreshToken'},
        )
        .timeout(_restoreTimeout);

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'];
    if (newAccessToken == null) return null;

    await _storage.write(
      key: _accessTokenKey,
      value: newAccessToken.toString(),
    );
    return newAccessToken.toString();
  }

  /// Used internally by [restoreSession] only — preserves its existing
  /// behavior exactly (any failure, including a network error, resolves
  /// to `null` here; `restoreSession` itself decides what that means).
  Future<String?> _refreshAccessToken() async {
    try {
      return await _performRefresh();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> refreshAccessToken() => _performRefresh();

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);

    await _storage.delete(key: _refreshTokenKey);

    await _storage.delete(key: _cachedUserKey);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> logout() async {
    await _clearTokens();
  }
}
