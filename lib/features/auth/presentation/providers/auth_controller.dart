import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/local/onboarding_store.dart';
import '../../data/auth_exception.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Swap this provider's override to point at an `ApiAuthRepository` once the
/// Flask endpoints are ready; the login/register screens themselves never
/// change.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(baseUrl: apiBaseUrl);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref, ref.watch(authRepositoryProvider));
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._repository) : super(const AuthState()) {
    _restoreSession();
  }

  final Ref _ref;
  final AuthRepository _repository;

  /// Marks this device as having completed a real sign-in at least once —
  /// the local signal `AuthGate` uses to route a later, unauthenticated
  /// session to Login rather than Register (see
  /// `hasCompletedInitialSetupProvider`). Called from every path that
  /// proves this device has actually authenticated; never undone except by
  /// the dev-only reset.
  Future<void> _markReturningUser() {
    return _ref.read(onboardingStoreProvider).markInitialSetupComplete();
  }

  Future<void> _restoreSession() async {
    final result = await _repository.restoreSession();
    state = switch (result.outcome) {
      SessionRestoreOutcome.authenticated => AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      ),
      SessionRestoreOutcome.noSession => const AuthState(
        status: AuthStatus.unauthenticated,
      ),
      SessionRestoreOutcome.unavailable => const AuthState(
        status: AuthStatus.unavailable,
      ),
    };
    if (result.outcome == SessionRestoreOutcome.authenticated) {
      await _markReturningUser();
    }
  }

  /// Retries restoring a stored session after [AuthStatus.unavailable] —
  /// wired to the "Try again" action so a transient connectivity issue
  /// never permanently strands the user.
  Future<void> retryRestoreSession() => _restoreSession();

  /// Lets a user stuck on [AuthStatus.unavailable] fall through to Login
  /// instead of waiting indefinitely for the server to come back.
  Future<void> continueToLogin() async {
    await _repository.logout();
    // Reaching `unavailable` in the first place required a stored (if
    // unverifiable) token, which only a real prior sign-in on this device
    // could have left behind — so this is provably a returning user, not a
    // fresh install.
    await _markReturningUser();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> login({required String email, required String password}) async {
    if (state.loginLoading) return false;
    state = state.copyWith(loginLoading: true, clearLoginError: true);

    try {
      final user = await _repository.login(email: email, password: password);
      await _markReturningUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (error) {
      state = state.copyWith(
        loginLoading: false,
        loginError: _friendlyMessage(error),
      );
      return false;
    }
  }

  /// Creates the account, then immediately signs in with the same
  /// credentials. The backend contract is unchanged — `/api/register`
  /// still doesn't return a session on its own — but the app no longer
  /// makes a brand-new user find and use a second, separate Login screen
  /// just to reach the account they only just created. If that follow-up
  /// sign-in itself fails (a rare, transient gap right after registering),
  /// the account still exists and this still reports success; the user
  /// simply lands whereever the normal unauthenticated routing (Login, since
  /// this device has never completed a sign-in yet) sends them next.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) async {
    if (state.registerLoading) return false;
    state = state.copyWith(registerLoading: true, clearRegisterError: true);

    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        username: username,
        password: password,
      );
    } catch (error) {
      state = state.copyWith(
        registerLoading: false,
        registerError: _friendlyMessage(error),
      );
      return false;
    }

    try {
      final user = await _repository.login(email: email, password: password);
      await _markReturningUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        registerLoading: false,
      );
    } catch (_) {
      state = state.copyWith(registerLoading: false);
    }
    return true;
  }

  /// Called when switching between Login and Register so a stale error
  /// from one never lingers into the other.
  void clearErrors() {
    state = state.copyWith(clearLoginError: true, clearRegisterError: true);
  }

  /// Clears the stored access/refresh tokens and the in-memory session —
  /// unlike just resetting [state], this actually revokes local access, so
  /// a later `restoreSession()` (e.g. on next launch) can't silently log
  /// the user back in with a stale token.
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _friendlyMessage(Object error) {
    if (error is AuthException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
