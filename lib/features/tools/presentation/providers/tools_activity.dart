import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activity/presentation/providers/activity_controller.dart';

/// Records a completed calculation into the Activity feed — called once
/// per explicit "Calculate" tap, never on every keystroke, so the feed
/// reflects deliberate actions. Only the 4 calculators the backend accepts
/// (`clientLoggableActivityTypes`) call this; best-effort — a failed log
/// doesn't undo or block the calculation the user already sees.
Future<void> recordCalculation(
  WidgetRef ref, {
  required String type,
  required String toolName,
  required String summary,
}) async {
  try {
    await ref
        .read(activityLogRepositoryProvider)
        .logActivity(type: type, title: toolName, description: summary);
  } catch (error) {
    debugPrint('Failed to log activity ($type): $error');
  }
}
