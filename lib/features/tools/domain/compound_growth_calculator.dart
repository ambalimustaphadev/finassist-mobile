import 'dart:math' as math;

/// Future value of a single lump sum growing at a fixed annual rate,
/// compounded [compoundingPerYear] times per year — no recurring
/// contributions (see `savings_calculator.dart` for that case).
double calculateCompoundGrowth({
  required double principal,
  required double annualInterestRatePercent,
  required int years,
  int compoundingPerYear = 12,
}) {
  if (years <= 0 || compoundingPerYear <= 0) return principal;

  final ratePerPeriod = annualInterestRatePercent / 100 / compoundingPerYear;
  final totalPeriods = compoundingPerYear * years;

  return principal * math.pow(1 + ratePerPeriod, totalPeriods).toDouble();
}
