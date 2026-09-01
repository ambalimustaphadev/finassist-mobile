import '../models/auth_user.dart';

/// Why session restoration resolved the way it did — lets `AuthController`
/// tell "no session, go to Login" apart from "there's a session, but we
/// couldn't reach the server to verify it", so a transient network blip
/// never silently signs the user out.
enum SessionRestoreOutcome { authenticated, noSession, unavailable }

class SessionRestoreResult {
  const SessionRestoreResult.authenticated(this.user)
    : outcome = SessionRestoreOutcome.authenticated;

  const SessionRestoreResult.noSession()
    : outcome = SessionRestoreOutcome.noSession,
      user = null;

  const SessionRestoreResult.unavailable()
    : outcome = SessionRestoreOutcome.unavailable,
      user = null;

  final SessionRestoreOutcome outcome;
  final AuthUser? user;
}

/// Source of authentication. The UI depends only on this interface, so a
/// real `ApiAuthRepository` can replace [MockAuthRepository] later without
/// any screen changes.
abstract class AuthRepository {
  /// Attempts to restore a previously-authenticated session (e.g. from a
  /// stored token). Must resolve within a reasonable time even if the
  /// backend is unreachable — see [SessionRestoreOutcome.unavailable] —
  /// so the app never hangs on an endless splash/loading state.
  Future<SessionRestoreResult> restoreSession();

  /// Throws [AuthException] with a friendly message on failure.
  Future<AuthUser> login({required String email, required String password});

  /// Throws [AuthException] with a friendly message on failure. Does not
  /// return the created user — registration does not auto-authenticate the
  /// session; the user logs in afterwards.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  });
  Future<void> logout();
}
