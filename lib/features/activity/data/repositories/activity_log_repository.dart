import '../models/activity_log_entry.dart';

abstract class ActivityLogRepository {
  Future<List<ActivityLogEntry>> getActivity();

  /// [type] must be one of [clientLoggableActivityTypes] — the backend
  /// rejects anything else with a 400.
  Future<void> logActivity({
    required String type,
    required String title,
    String? description,
  });
}
