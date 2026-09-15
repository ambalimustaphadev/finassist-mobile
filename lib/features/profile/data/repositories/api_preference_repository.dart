import '../../../../core/network/api_client.dart';
import '../models/preferences.dart';
import 'preference_repository.dart';

class ApiPreferenceRepository implements PreferenceRepository {
  ApiPreferenceRepository({required String baseUrl, ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  @override
  Future<Preferences> getPreferences() async {
    final json = await _client.get('/api/preferences');
    return Preferences.fromJson(json);
  }

  @override
  Future<Preferences> updatePreferences(Map<String, dynamic> changes) async {
    final json = await _client.patch('/api/preferences', changes);
    return Preferences.fromJson(json);
  }
}
