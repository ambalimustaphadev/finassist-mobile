/// Mirrors `notification_to_dict` in the backend's
/// `services/notification_service.py` exactly. Named `AppNotification`
/// (not `Notification`) to avoid colliding with Flutter's own
/// `Notification` class used by its widget-notification-bubbling system.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.read,
    required this.createdAt,
    this.body,
  });

  final int id;
  final String type;
  final String title;
  final String? body;
  final bool read;
  final DateTime createdAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
