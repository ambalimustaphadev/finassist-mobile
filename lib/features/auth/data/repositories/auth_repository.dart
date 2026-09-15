import '../models/auth_user.dart';

/// Why session restoration resolved the way it did — lets `AuthController`
/// tell "no session, go to Login" apart from "there's a session, but we
/// couldn't reach the server to verify it", so a transient network blip
/// never silently signs the user out. [unavailable] is now a rare fallback:
/// an unreachable/erroring backend normally still resolves as
/// [authenticated] (using the last-known cached user — see
/// `ApiAuthRepository._optimisticFromCache`) so the app isn't blocked
/// behind a global connection error; [unavailable] only surfaces if no
/// user was ever cached for the stored token.
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

  /// Attempts to refresh the access token using the existing stored
  /// refresh token, persisting the new access token to the existing
  /// secure storage on success — the same mechanism `restoreSession()`
  /// already uses internally on a 401 from `/api/me`, exposed here so
  /// other authenticated repositories (e.g. chat) can transparently
  /// retry a request whose access token expired mid-session.
  ///
  /// Returns the new access token on success, or `null` only for a
  /// *definitive* rejection — no refresh token is stored, or the server
  /// explicitly rejected it. A network/timeout failure while trying to
  /// reach the refresh endpoint itself is thrown instead of returned as
  /// `null`, so callers never mistake "couldn't reach the server" for
  /// "this session is invalid."
  Future<String?> refreshAccessToken();
}
