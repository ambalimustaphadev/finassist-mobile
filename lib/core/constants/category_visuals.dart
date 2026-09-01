import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/models/spending_category_type.dart';

/// Maps a [SpendingCategoryType] to its icon and accent color. Kept in one
/// place so the legend, insights and chat breakdown cards stay in sync.
class CategoryVisual {
  const CategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

const Map<SpendingCategoryType, CategoryVisual> categoryVisuals = {
  SpendingCategoryType.foodAndDining: CategoryVisual(
    icon: Icons.restaurant_rounded,
    color: AppColors.categoryFood,
  ),
  SpendingCategoryType.transfers: CategoryVisual(
    icon: Icons.swap_horiz_rounded,
    color: AppColors.categoryTransfers,
  ),
  SpendingCategoryType.shopping: CategoryVisual(
    icon: Icons.shopping_bag_rounded,
    color: AppColors.categoryShopping,
  ),
  SpendingCategoryType.bills: CategoryVisual(
    icon: Icons.bolt_rounded,
    color: AppColors.categoryBills,
  ),
  SpendingCategoryType.others: CategoryVisual(
    icon: Icons.more_horiz_rounded,
    color: AppColors.categoryOthers,
  ),
};
