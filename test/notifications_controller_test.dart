import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/core/network/pagination.dart';
import 'package:finassist/features/notifications/data/models/notification.dart';
import 'package:finassist/features/notifications/data/repositories/notification_repository.dart';
import 'package:finassist/features/notifications/presentation/providers/notifications_controller.dart';

class _FakeRepo implements NotificationRepository {
  _FakeRepo({List<AppNotification>? seed, this.errorOnLoad})
    : _notifications = List.of(seed ?? const []);

  final List<AppNotification> _notifications;
  final ApiException? errorOnLoad;

  @override
  Future<Paginated<AppNotification>> getNotifications({int page = 1}) async {
    if (errorOnLoad != null) throw errorOnLoad!;
    return Paginated(
      items: List.of(_notifications),
      pagination: Pagination(
        page: page,
        perPage: 20,
        total: _notifications.length,
      ),
    );
  }

  @override
  Future<void> markRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(read: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
  }
}

AppNotification _notification({int id = 1, bool read = false}) {
  return AppNotification(
    id: id,
    type: 'goal_overdue',
    title: 'Vacation fund is overdue',
    read: read,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test(
    'starts empty with no fabricated sample notification, then loads real ones',
    () async {
      final controller = NotificationsController(
        _FakeRepo(seed: [_notification()]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, NotificationsLoadStatus.loaded);
      expect(controller.state.notifications, hasLength(1));
      expect(controller.state.hasUnread, isTrue);
    },
  );

  test(
    'an empty backend list is an honest empty state, not an error',
    () async {
      final controller = NotificationsController(_FakeRepo());
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.status, NotificationsLoadStatus.loaded);
      expect(controller.state.notifications, isEmpty);
      expect(controller.state.hasUnread, isFalse);
    },
  );

  test('a load failure surfaces a clear error, not a crash', () async {
    final controller = NotificationsController(
      _FakeRepo(errorOnLoad: const ApiException("Couldn't connect.")),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, NotificationsLoadStatus.error);
    expect(controller.state.loadError, isNotNull);
  });

  test('markRead flips just that notification to read', () async {
    final controller = NotificationsController(
      _FakeRepo(seed: [_notification(id: 1), _notification(id: 2)]),
    );
    await Future<void>.delayed(Duration.zero);

    await controller.markRead(1);

    final one = controller.state.notifications.firstWhere((n) => n.id == 1);
    final two = controller.state.notifications.firstWhere((n) => n.id == 2);
    expect(one.read, isTrue);
    expect(two.read, isFalse);
    expect(controller.state.hasUnread, isTrue);
  });

  test('markAllRead flips every notification to read', () async {
    final controller = NotificationsController(
      _FakeRepo(seed: [_notification(id: 1), _notification(id: 2)]),
    );
    await Future<void>.delayed(Duration.zero);

    await controller.markAllRead();

    expect(controller.state.hasUnread, isFalse);
    expect(controller.state.notifications.every((n) => n.read), isTrue);
  });
}
