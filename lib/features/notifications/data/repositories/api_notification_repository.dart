import '../../../../core/network/api_client.dart';
import '../../../../core/network/pagination.dart';
import '../models/notification.dart';
import 'notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({required String baseUrl, ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  @override
  Future<Paginated<AppNotification>> getNotifications({int page = 1}) async {
    final json = await _client.get(
      '/api/notifications',
      query: {'page': '$page'},
    );
    final items = (json['items'] as List?) ?? const [];
    return Paginated(
      items: items
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Future<void> markRead(int id) {
    return _client.patch('/api/notifications/$id', const {});
  }

  @override
  Future<void> markAllRead() {
    return _client.patch('/api/notifications/read-all', const {});
  }
}
