import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/category_visuals.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/models/category_breakdown.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../../shared/widgets/transaction_row.dart';
import '../../../dashboard/presentation/widgets/spending_donut_chart.dart';

/// The rich card embedded inside an AI response that breaks a single
/// spending category down into its top transactions.
class FinancialBreakdownCard extends StatelessWidget {
  const FinancialBreakdownCard({
    super.key,
    required this.breakdown,
    this.onViewAll,
  });

  final CategoryBreakdown breakdown;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisuals[breakdown.category]!;

    return AppCard(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: visual.icon, color: visual.color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breakdown.category.label,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breakdown.amount.toNaira(),
                      style: AppTypography.financialNumberMedium,
                    ),
                  ],
                ),
              ),
              SpendingDonutChart(
                categories: breakdown.allCategories,
                size: 56,
                strokeWidth: 7,
                centerChild: Text(
                  breakdown.percentageOfTotal.toPercentage(decimals: 1),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${breakdown.percentageOfTotal.toPercentage()} of total spending',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Top transactions in this category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: onViewAll,
                child: Text(
                  'View all',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: AppSpacing.lg),
          for (final txn in breakdown.topTransactions)
            TransactionRow(
              title: txn.merchantName,
              subtitle: txn.date.toMonthDayYear(),
              amount: txn.amount,
            ),
          TransactionRow(
            title: 'Others',
            subtitle: '${breakdown.otherTransactionsCount} transactions',
            amount: breakdown.otherTransactionsAmount,
            icon: Icons.more_horiz_rounded,
          ),
        ],
      ),
    );
  }
}
