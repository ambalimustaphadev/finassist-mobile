import 'dart:math' as math;

/// Future value of a starting balance plus regular monthly contributions,
/// growing at [annualInterestRatePercent] compounded monthly — the
/// standard ordinary-annuity formula, with a zero-interest fallback so
/// dividing by a zero rate never happens.
double calculateFutureSavings({
  required double monthlyContribution,
  required double annualInterestRatePercent,
  required int months,
  double startingBalance = 0,
}) {
  if (months <= 0) return startingBalance;

  final monthlyRate = annualInterestRatePercent / 100 / 12;

  if (monthlyRate == 0) {
    return startingBalance + monthlyContribution * months;
  }

  final growthFactor = math.pow(1 + monthlyRate, months).toDouble();
  final futureValueOfStart = startingBalance * growthFactor;
  final futureValueOfContributions =
      monthlyContribution * ((growthFactor - 1) / monthlyRate);

  return futureValueOfStart + futureValueOfContributions;
}
