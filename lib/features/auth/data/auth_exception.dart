/// A user-presentable authentication failure. Repositories are responsible
/// for translating raw HTTP/network errors into one of these so the UI
/// never has to interpret status codes or exceptions itself.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
