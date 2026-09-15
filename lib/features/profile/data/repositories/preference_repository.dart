import '../models/preferences.dart';

/// Source of the real, backend-authoritative preferences — `GET/PATCH
/// /api/preferences`. This is the single source of truth for currency and
/// language; nothing else in the app should keep its own copy.
abstract class PreferenceRepository {
  Future<Preferences> getPreferences();

  /// [changes] uses real backend field names (e.g. `{"currency": "USD"}`)
  /// — only the keys present are updated server-side.
  Future<Preferences> updatePreferences(Map<String, dynamic> changes);
}
