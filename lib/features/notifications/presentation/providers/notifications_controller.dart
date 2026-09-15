import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/pagination.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/api_notification_repository.dart';
import '../../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository(baseUrl: apiBaseUrl);
});

/// Rebuilt whenever the authenticated user changes — same pattern as every
/// other per-user controller in this app. Shared by Profile's bell icon
/// (just needs `hasUnread`) and the full `NotificationsScreen`, so opening
/// the screen never re-fetches what the bell icon already loaded.
final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
      ref.watch(authControllerProvider.select((state) => state.user?.id));
      return NotificationsController(ref.watch(notificationRepositoryProvider));
    });

enum NotificationsLoadStatus { loading, loaded, error }

class NotificationsState {
  const NotificationsState({
    this.status = NotificationsLoadStatus.loading,
    this.notifications = const [],
    this.loadError,
    this.pagination,
    this.isLoadingMore = false,
    this.isMarkingAll = false,
  });

  final NotificationsLoadStatus status;
  final List<AppNotification> notifications;
  final String? loadError;
  final Pagination? pagination;
  final bool isLoadingMore;
  final bool isMarkingAll;

  bool get hasUnread => notifications.any((n) => !n.read);
  bool get hasMore => pagination?.hasMore ?? false;

  NotificationsState copyWith({
    NotificationsLoadStatus? status,
    List<AppNotification>? notifications,
    String? loadError,
    bool clearLoadError = false,
    Pagination? pagination,
    bool? isLoadingMore,
    bool? isMarkingAll,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      pagination: pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
    );
  }
}

/// Coordinates the real, backend-authoritative notification inbox. An
/// empty list is the honest, expected state today — the backend has no
/// trigger that creates a notification yet (see `notification_service.py`)
/// — never fabricated with sample entries.
class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._repository)
    : super(const NotificationsState()) {
    _load();
  }

  final NotificationRepository _repository;

  Future<void> _load() async {
    state = state.copyWith(
      status: NotificationsLoadStatus.loading,
      clearLoadError: true,
    );
    try {
      final page = await _repository.getNotifications();
      state = state.copyWith(
        status: NotificationsLoadStatus.loaded,
        notifications: page.items,
        pagination: page.pagination,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: NotificationsLoadStatus.error,
        loadError: e.message,
      );
    }
  }

  Future<void> refresh() => _load();

  Future<void> loadMore() async {
    final pagination = state.pagination;
    if (pagination == null || !pagination.hasMore || state.isLoadingMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repository.getNotifications(
        page: pagination.page + 1,
      );
      state = state.copyWith(
        notifications: [...state.notifications, ...page.items],
        pagination: page.pagination,
        isLoadingMore: false,
      );
    } on ApiException {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Optimistically marks [id] read locally, then confirms with the
  /// server — on failure, reverts so the UI never claims something it
  /// didn't actually persist.
  Future<void> markRead(int id) async {
    final notification = state.notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => AppNotification(
        id: id,
        type: '',
        title: '',
        read: true,
        createdAt: DateTime.now(),
      ),
    );
    if (notification.read) return;

    state = state.copyWith(
      notifications: [
        for (final n in state.notifications)
          if (n.id == id) n.copyWith(read: true) else n,
      ],
    );
    try {
      await _repository.markRead(id);
    } on ApiException {
      state = state.copyWith(
        notifications: [
          for (final n in state.notifications)
            if (n.id == id) n.copyWith(read: false) else n,
        ],
      );
    }
  }

  Future<void> markAllRead() async {
    if (!state.hasUnread || state.isMarkingAll) return;
    final previous = state.notifications;
    state = state.copyWith(
      isMarkingAll: true,
      notifications: [for (final n in previous) n.copyWith(read: true)],
    );
    try {
      await _repository.markAllRead();
      state = state.copyWith(isMarkingAll: false);
    } on ApiException {
      state = state.copyWith(isMarkingAll: false, notifications: previous);
    }
  }
}
