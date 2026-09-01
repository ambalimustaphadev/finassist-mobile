/// The authenticated user, as returned by the backend after login or
/// pulled from a restored session.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;

  /// Defensive against slightly different key casing/naming across backend
  /// versions — falls back sensibly rather than throwing on a missing field.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    return AuthUser(
      id: read(['id', 'user_id', 'userId']),
      firstName: read(['first_name', 'firstName']),
      lastName: read(['last_name', 'lastName']),
      email: read(['email']),
      username: read(['username']),
    );
  }
}
