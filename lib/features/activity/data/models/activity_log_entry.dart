/// Mirrors `activity_to_dict` in the backend's `services/activity_service.py`
/// — one real, server-recorded event, posted by the client for the 4
/// calculator types it's allowed to log (see [clientLoggableActivityTypes]).
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.description,
  });

  final int id;
  final String type;
  final String title;
  final String? description;
  final DateTime createdAt;

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Exactly the types `services/activity_service.py`'s `CLIENT_LOGGABLE_TYPES`
/// accepts from `POST /api/activity` — anything else is rejected with a 400.
const clientLoggableActivityTypes = {
  'currency_conversion',
  'loan_calculation',
  'savings_calculation',
  'affordability_calculation',
};
