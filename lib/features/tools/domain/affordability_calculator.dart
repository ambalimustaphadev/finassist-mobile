/// The extra monthly payment (loan, rent, etc.) someone could take on
/// without their total monthly debt exceeding [maxDebtToIncomeRatio] of
/// their income — the standard debt-to-income guideline lenders use.
/// Never negative: a household already over the ratio can afford nothing
/// more, not a negative amount.
double calculateMaxAffordablePayment({
  required double monthlyIncome,
  required double existingMonthlyDebt,
  double maxDebtToIncomeRatio = 0.36,
}) {
  final maxTotalDebt = monthlyIncome * maxDebtToIncomeRatio;
  final remaining = maxTotalDebt - existingMonthlyDebt;
  return remaining < 0 ? 0 : remaining;
}
