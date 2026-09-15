import 'dart:io';

import '../models/profile.dart';

/// Source of the real, backend-authoritative profile — `GET/PATCH
/// /api/profile` and `POST /api/profile/picture`.
abstract class ProfileRepository {
  Future<Profile> getProfile();

  /// [changes] is a partial map of backend field names (e.g.
  /// `{"first_name": "Ada", "income": 500000}`) — only the keys present are
  /// updated server-side.
  Future<Profile> updateProfile(Map<String, dynamic> changes);

  Future<Profile> uploadProfilePicture(File file);
}
