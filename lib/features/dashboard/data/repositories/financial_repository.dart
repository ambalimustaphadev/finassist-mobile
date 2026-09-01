import '../../../../shared/models/bank_statement.dart';
import '../../../../shared/models/category_breakdown.dart';
import '../../../../shared/models/spending_category.dart';
import '../../../../shared/models/spending_category_type.dart';
import '../models/financial_insight.dart';
import '../models/spending_summary.dart';

/// Source of the user's financial data. The dashboard depends only on this
/// interface, so a real backend-backed [FinancialRepository] can replace
/// [MockFinancialRepository] without any UI changes.
abstract class FinancialRepository {
  Future<BankStatement> getStatement();

  Future<SpendingSummary> getSpendingSummary();

  Future<List<SpendingCategory>> getSpendingCategories();

  Future<List<FinancialInsight>> getInsights();

  Future<CategoryBreakdown> getCategoryBreakdown(SpendingCategoryType category);
}
