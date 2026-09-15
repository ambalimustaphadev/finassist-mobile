import '../../../../core/network/pagination.dart';
import '../models/notification.dart';

abstract class NotificationRepository {
  Future<Paginated<AppNotification>> getNotifications({int page = 1});

  Future<void> markRead(int id);

  Future<void> markAllRead();
}
