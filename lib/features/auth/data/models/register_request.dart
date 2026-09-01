/// Request payload for `POST /api/register`. Field names deliberately
/// match the Flask backend's expected keys exactly — `confirmPassword`
/// never reaches this DTO, and the backend (not this app) hashes the
/// plain-text password.
class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'username': username,
    'password': password,
  };
}
