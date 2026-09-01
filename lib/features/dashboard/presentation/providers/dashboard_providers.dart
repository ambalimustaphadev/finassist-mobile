import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/bank_statement.dart';
import '../../../../shared/models/spending_category.dart';
import '../../data/models/financial_insight.dart';
import '../../data/models/spending_summary.dart';
import '../../data/repositories/financial_repository.dart';
import '../../data/repositories/mock_financial_repository.dart';

/// Swap this provider's override to point at an `ApiFinancialRepository`
/// once a real backend exists; nothing downstream needs to change.
final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  return MockFinancialRepository();
});

final statementProvider = FutureProvider<BankStatement>((ref) {
  return ref.watch(financialRepositoryProvider).getStatement();
});

final spendingSummaryProvider = FutureProvider<SpendingSummary>((ref) {
  return ref.watch(financialRepositoryProvider).getSpendingSummary();
});

final spendingCategoriesProvider = FutureProvider<List<SpendingCategory>>((
  ref,
) {
  return ref.watch(financialRepositoryProvider).getSpendingCategories();
});

final insightsProvider = FutureProvider<List<FinancialInsight>>((ref) {
  return ref.watch(financialRepositoryProvider).getInsights();
});

/// Ticks once a minute so time-sensitive UI (the dashboard greeting) stays
/// current without the user needing to refresh or reopen the app.
final currentTimeProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

/// Which bottom-nav tab is active on the dashboard shell — an index into
/// `AppBottomNavBar`'s items (0 = Home, [profileNavIndex] = Profile).
/// Switching it swaps the shell's body in place rather than pushing a new
/// route, so the bottom nav — and the rest of the shell — never
/// disappears the way a full-screen push would make it.
final dashboardTabProvider = StateProvider<int>((ref) => 0);
