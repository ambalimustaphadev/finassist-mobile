import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/models/spending_category.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/spending_summary.dart';
import 'spending_category_legend.dart';
import 'spending_donut_chart.dart';

/// The dashboard's main "Spending overview" card: total spend, month-over-
/// month comparison, donut chart and per-category legend.
class SpendingOverviewCard extends StatelessWidget {
  const SpendingOverviewCard({
    super.key,
    required this.summary,
    required this.categories,
  });

  final SpendingSummary summary;
  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    final isIncrease = summary.comparisonPercentage >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending overview',
                  style: AppTypography.sectionHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(summary.periodLabel, style: AppTypography.body),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.totalAmount.toNaira(),
                      style: AppTypography.financialNumberLarge,
                    ),
                    const SizedBox(height: 4),
                    Text('Total spending', style: AppTypography.body),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          isIncrease
                              ? Icons.arrow_outward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 15,
                          color: AppColors.accentStrong,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${summary.comparisonPercentage.toPercentage()} ${summary.comparisonLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentStrong,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SpendingDonutChart(
                categories: categories,
                centerChild: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SpendingCategoryLegend(categories: categories),
        ],
      ),
    );
  }
}
