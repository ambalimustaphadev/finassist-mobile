import 'spending_category.dart';
import 'spending_category_type.dart';
import 'transaction.dart';

/// A detailed breakdown of a single spending category, used to render the
/// embedded financial card inside an AI chat response.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentageOfTotal,
    required this.topTransactions,
    required this.otherTransactionsCount,
    required this.otherTransactionsAmount,
    required this.allCategories,
  });

  final SpendingCategoryType category;
  final double amount;
  final double percentageOfTotal;
  final List<Transaction> topTransactions;
  final int otherTransactionsCount;
  final double otherTransactionsAmount;

  /// The full category distribution for the period, so the breakdown card
  /// can render the same donut chart context shown on the dashboard.
  final List<SpendingCategory> allCategories;
}
