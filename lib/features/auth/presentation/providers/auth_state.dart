import '../../data/models/auth_user.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,

  /// A stored session exists but couldn't be verified because the backend
  /// was unreachable — distinct from [unauthenticated] so the UI can offer
  /// "Try again" instead of silently dropping the user to Login and
  /// discarding a session that may still be valid.
  unavailable,
}

/// Session-level auth state.
///
/// Login and Register each get their own loading/error fields
/// ([loginLoading]/[loginError] vs [registerLoading]/[registerError])
/// rather than one shared pair — a failed registration must never surface
/// on the Login screen (and vice versa), and a single shared field can't
/// express that. Neither is part of [status], since a failed attempt at
/// either doesn't change whether a session exists.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.loginLoading = false,
    this.loginError,
    this.registerLoading = false,
    this.registerError,
  });

  final AuthStatus status;
  final AuthUser? user;

  final bool loginLoading;
  final String? loginError;

  final bool registerLoading;
  final String? registerError;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? loginLoading,
    String? loginError,
    bool clearLoginError = false,
    bool? registerLoading,
    String? registerError,
    bool clearRegisterError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      loginLoading: loginLoading ?? this.loginLoading,
      loginError: clearLoginError ? null : (loginError ?? this.loginError),
      registerLoading: registerLoading ?? this.registerLoading,
      registerError: clearRegisterError
          ? null
          : (registerError ?? this.registerError),
    );
  }
}
