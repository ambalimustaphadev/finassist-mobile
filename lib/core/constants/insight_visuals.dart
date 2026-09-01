import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/dashboard/data/models/financial_insight.dart';

/// Maps a [FinancialInsightType] to its icon and accent color.
class InsightVisual {
  const InsightVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

const Map<FinancialInsightType, InsightVisual> insightVisuals = {
  FinancialInsightType.spendingIncrease: InsightVisual(
    icon: Icons.trending_up_rounded,
    color: AppColors.accentStrong,
  ),
  FinancialInsightType.recurringPayments: InsightVisual(
    icon: Icons.event_repeat_rounded,
    color: AppColors.categoryTransfers,
  ),
  FinancialInsightType.topCategory: InsightVisual(
    icon: Icons.lightbulb_rounded,
    color: AppColors.categoryShopping,
  ),
};
