import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/api_activity_log_repository.dart';

/// The activity log repository — used by Tools calculators
/// (`recordCalculation` in `tools_activity.dart`) to log a completed
/// calculation, independent of any activity-feed UI.
final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return ApiActivityLogRepository(baseUrl: apiBaseUrl);
});
