import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/category_visuals.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/models/spending_category.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// The row of category icons with percentage/amount beneath the donut
/// chart on the dashboard's spending overview card.
class SpendingCategoryLegend extends StatelessWidget {
  const SpendingCategoryLegend({super.key, required this.categories});

  final List<SpendingCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in categories)
          Expanded(child: _LegendItem(category: category)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.category});

  final SpendingCategory category;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisuals[category.type]!;
    return Column(
      children: [
        IconBadge(
          icon: visual.icon,
          color: visual.color,
          size: 36,
          iconSize: 18,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          category.type.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          category.percentage.toPercentage(),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          category.amount.toNaira(),
          style: AppTypography.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
