import '../../../../shared/models/bank_statement.dart';
import '../../../../shared/models/category_breakdown.dart';
import '../../../../shared/models/spending_category.dart';
import '../../../../shared/models/spending_category_type.dart';
import '../../../../shared/models/transaction.dart';
import '../models/financial_insight.dart';
import '../models/spending_summary.dart';
import 'financial_repository.dart';

/// In-memory mock of [FinancialRepository]. Mirrors the shape a real API
/// response would take so it can be swapped for an `ApiFinancialRepository`
/// later without touching the dashboard UI.
class MockFinancialRepository implements FinancialRepository {
  static final BankStatement _statement = BankStatement(
    fileName: 'Stanbic IBTC Statement.pdf',
    institution: 'Stanbic IBTC',
    periodStart: DateTime(2024, 5, 1),
    periodEnd: DateTime(2024, 5, 31),
  );

  static const List<SpendingCategory> _categories = [
    SpendingCategory(
      type: SpendingCategoryType.foodAndDining,
      amount: 142500,
      percentage: 29.4,
    ),
    SpendingCategory(
      type: SpendingCategoryType.transfers,
      amount: 120000,
      percentage: 24.7,
    ),
    SpendingCategory(
      type: SpendingCategoryType.shopping,
      amount: 79200,
      percentage: 16.3,
    ),
    SpendingCategory(
      type: SpendingCategoryType.bills,
      amount: 68800,
      percentage: 14.2,
    ),
    SpendingCategory(
      type: SpendingCategoryType.others,
      amount: 74700,
      percentage: 15.4,
    ),
  ];

  static final List<Transaction> _foodTransactions = [
    Transaction(
      id: 'txn-kfc-1',
      merchantName: 'KFC, Bodija',
      date: DateTime(2024, 5, 28),
      amount: 18500,
      category: SpendingCategoryType.foodAndDining,
    ),
    Transaction(
      id: 'txn-dominos-1',
      merchantName: "Domino's Pizza",
      date: DateTime(2024, 5, 24),
      amount: 15000,
      category: SpendingCategoryType.foodAndDining,
    ),
    Transaction(
      id: 'txn-shoprite-1',
      merchantName: 'Shoprite, Ibadan',
      date: DateTime(2024, 5, 21),
      amount: 12650,
      category: SpendingCategoryType.foodAndDining,
    ),
  ];

  static const List<FinancialInsight> _insights = [
    FinancialInsight(
      id: 'insight-1',
      type: FinancialInsightType.spendingIncrease,
      message: 'You spent 18% more on Food & Dining compared to last month.',
      highlights: ['18%', 'Food & Dining'],
    ),
    FinancialInsight(
      id: 'insight-2',
      type: FinancialInsightType.recurringPayments,
      message: 'You have 4 recurring payments totaling ₦27,500.',
      highlights: ['4 recurring payments'],
    ),
    FinancialInsight(
      id: 'insight-3',
      type: FinancialInsightType.topCategory,
      message: 'Your biggest spending category is Food & Dining.',
      highlights: ['Food & Dining'],
    ),
  ];

  @override
  Future<BankStatement> getStatement() async => _statement;

  @override
  Future<SpendingSummary> getSpendingSummary() async => const SpendingSummary(
    totalAmount: 485200,
    comparisonPercentage: 12.5,
    periodLabel: 'This month',
    comparisonLabel: 'vs last month',
  );

  @override
  Future<List<SpendingCategory>> getSpendingCategories() async => _categories;

  @override
  Future<List<FinancialInsight>> getInsights() async => _insights;

  @override
  Future<CategoryBreakdown> getCategoryBreakdown(
    SpendingCategoryType category,
  ) async {
    final match = _categories.firstWhere((c) => c.type == category);
    return CategoryBreakdown(
      category: category,
      amount: match.amount,
      percentageOfTotal: match.percentage,
      topTransactions: _foodTransactions,
      otherTransactionsCount: 12,
      otherTransactionsAmount: 96350,
      allCategories: _categories,
    );
  }
}
