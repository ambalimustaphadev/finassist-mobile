import 'dart:math';

import '../auth_exception.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

class _MockAccount {
  _MockAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;

  AuthUser toAuthUser() {
    return AuthUser(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: username,
    );
  }
}

/// In-memory mock of [AuthRepository] so the login/register flow, its
/// validation, loading and error states are fully demoable before the Flask
/// endpoints are wired up. Seeded with one demo account so login can be
/// tried immediately without registering first.
///
/// To manually exercise the error path, log in with
/// `error@finassist.test` — any password fails with a friendly message.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _accounts['demo@finassist.com'] = _MockAccount(
      id: 'demo-user',
      firstName: 'Mustapha',
      lastName: 'Ambali',
      email: 'demo@finassist.com',
      username: 'mustapha',
      password: 'password123',
    );
  }

  final Map<String, _MockAccount> _accounts = {}; // keyed by lowercase email
  final Random _random = Random();

  Future<void> _simulateLatency() {
    return Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));
  }

  @override
  Future<SessionRestoreResult> restoreSession() async =>
      const SessionRestoreResult.noSession();

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    await _simulateLatency();

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == 'error@finassist.test') {
      throw const AuthException("That email or password doesn't look right.");
    }

    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      throw const AuthException("That email or password doesn't look right.");
    }

    return account.toAuthUser();
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    await _simulateLatency();

    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      throw const AuthException('That email is already registered.');
    }
    final usernameTaken = _accounts.values.any(
      (account) =>
          account.username.toLowerCase() == username.trim().toLowerCase(),
    );
    if (usernameTaken) {
      throw const AuthException('That username is already taken.');
    }

    _accounts[normalizedEmail] = _MockAccount(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      username: username.trim(),
      password: password,
    );
  }

  @override
  Future<void> logout() async {}
}
