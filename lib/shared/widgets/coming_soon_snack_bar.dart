import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Same "not built yet" affordance already used by the dashboard's bottom
/// nav — reused here so Profile rows without a backend/feature behind them
/// yet communicate that honestly instead of pretending to do something.
void showComingSoonSnackBar(BuildContext context, String featureName) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          '$featureName is coming soon',
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
}
