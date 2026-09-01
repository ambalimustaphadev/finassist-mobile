import 'spending_category_type.dart';

/// A single category's share of a spending period, e.g. Food & Dining at
/// 29.4% of total spend for the month.
class SpendingCategory {
  const SpendingCategory({
    required this.type,
    required this.amount,
    required this.percentage,
  });

  final SpendingCategoryType type;
  final double amount;

  /// Percentage of total spending, expressed 0-100.
  final double percentage;
}
