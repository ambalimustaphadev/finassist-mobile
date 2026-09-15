import '../../../../core/network/api_client.dart';
import '../models/activity_log_entry.dart';
import 'activity_log_repository.dart';

class ApiActivityLogRepository implements ActivityLogRepository {
  ApiActivityLogRepository({required String baseUrl, ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  @override
  Future<List<ActivityLogEntry>> getActivity() async {
    final json = await _client.get('/api/activity');
    final items = (json['items'] as List?) ?? const [];
    return items
        .map((item) => ActivityLogEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> logActivity({
    required String type,
    required String title,
    String? description,
  }) async {
    await _client.post('/api/activity', {
      'type': type,
      'title': title,
      'description': ?description,
    });
  }
}
