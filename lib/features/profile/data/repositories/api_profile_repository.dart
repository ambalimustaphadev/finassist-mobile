import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

import '../../../../core/network/api_client.dart';
import '../models/profile.dart';
import 'profile_repository.dart';

/// The only image formats the backend/R2 pipeline accepts for a profile
/// picture — kept in sync with the backend's own validation message below.
const _supportedProfilePictureTypes = {'image/jpeg', 'image/png', 'image/webp'};

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({required String baseUrl, ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  @override
  Future<Profile> getProfile() async {
    final json = await _client.get('/api/profile');
    return Profile.fromJson(json);
  }

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) async {
    final json = await _client.patch('/api/profile', changes);
    return Profile.fromJson(json);
  }

  @override
  Future<Profile> uploadProfilePicture(File file) async {
    final contentType = await detectImageContentType(file);
    if (!_supportedProfilePictureTypes.contains(contentType)) {
      throw const ApiException('Profile image must be JPEG, PNG, or WEBP.');
    }

    final json = await _client.uploadMultipart(
      '/api/profile/picture',
      fieldName: 'file',
      file: file,
      contentType: contentType,
    );
    if (kDebugMode) {
      debugPrint('[ApiProfileRepository] POST /api/profile/picture -> $json');
    }
    return Profile.fromJson(json);
  }
}

/// Sniffs [file]'s actual magic-number signature (falling back to its
/// extension only when the content itself is inconclusive) rather than
/// trusting a user- or picker-controlled filename — a renamed non-image
/// file must be rejected even with a `.jpg` extension, and a genuine image
/// must be accepted even if the picker gave it an odd or missing one.
/// Returns null if the type can't be determined at all.
Future<String?> detectImageContentType(File file) async {
  try {
    final raf = await file.open();
    final List<int> header;
    try {
      header = await raf.read(defaultMagicNumbersMaxLength);
    } finally {
      await raf.close();
    }
    return lookupMimeType(file.path, headerBytes: header);
  } catch (_) {
    return null;
  }
}
