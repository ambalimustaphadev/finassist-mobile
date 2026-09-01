import 'spending_category_type.dart';

/// A single dated transaction attributed to a spending category.
class Transaction {
  const Transaction({
    required this.id,
    required this.merchantName,
    required this.date,
    required this.amount,
    required this.category,
  });

  final String id;
  final String merchantName;
  final DateTime date;
  final double amount;
  final SpendingCategoryType category;
}
