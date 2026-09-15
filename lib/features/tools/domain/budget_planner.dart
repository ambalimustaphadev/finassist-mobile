/// The classic 50/30/20 split (needs/wants/savings), applied to whatever
/// percentages the user chooses — a deterministic allocation, not an AI
/// guess, so the same income always produces the same numbers.
class BudgetSplit {
  const BudgetSplit({
    required this.needs,
    required this.wants,
    required this.savings,
  });

  final double needs;
  final double wants;
  final double savings;
}

BudgetSplit calculateBudgetSplit(
  double monthlyIncome, {
  double needsPercent = 50,
  double wantsPercent = 30,
  double savingsPercent = 20,
}) {
  return BudgetSplit(
    needs: monthlyIncome * needsPercent / 100,
    wants: monthlyIncome * wantsPercent / 100,
    savings: monthlyIncome * savingsPercent / 100,
  );
}
