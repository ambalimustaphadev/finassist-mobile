/// Mirrors `GET/PATCH /api/profile`'s exact response shape — the real,
/// backend-authoritative user profile (as opposed to `AuthUser`, which is
/// the smaller object `/api/login`/`/api/me` return).
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.currency,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.country,
    this.occupation,
    this.employmentStatus,
    this.income,
    this.incomeFrequency,
    this.profilePictureUrl,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? country;
  final String currency;
  final String? occupation;
  final String? employmentStatus;
  final double? income;
  final String? incomeFrequency;
  final String? profilePictureUrl;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: json['country'] as String?,
      currency: json['currency'] as String? ?? 'NGN',
      occupation: json['occupation'] as String?,
      employmentStatus: json['employment_status'] as String?,
      income: (json['income'] as num?)?.toDouble(),
      incomeFrequency: json['income_frequency'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Valid values for `employment_status`, exactly as validated server-side.
const employmentStatusOptions = [
  'employed',
  'self_employed',
  'unemployed',
  'student',
  'retired',
  'other',
];

/// Valid values for `income_frequency`, exactly as validated server-side.
const incomeFrequencyOptions = ['weekly', 'biweekly', 'monthly', 'yearly'];
