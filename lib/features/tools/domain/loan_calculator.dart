import 'dart:math' as math;

/// Standard amortizing-loan figures: a fixed monthly payment, its total
/// over the full term, and the interest portion of that total.
class LoanResult {
  const LoanResult({
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
  });

  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
}

LoanResult calculateLoan({
  required double principal,
  required double annualInterestRatePercent,
  required int termMonths,
}) {
  if (termMonths <= 0 || principal <= 0) {
    return const LoanResult(
      monthlyPayment: 0,
      totalPayment: 0,
      totalInterest: 0,
    );
  }

  final monthlyRate = annualInterestRatePercent / 100 / 12;

  final double monthlyPayment;
  if (monthlyRate == 0) {
    monthlyPayment = principal / termMonths;
  } else {
    final growthFactor = math.pow(1 + monthlyRate, termMonths).toDouble();
    monthlyPayment =
        principal * monthlyRate * growthFactor / (growthFactor - 1);
  }

  final totalPayment = monthlyPayment * termMonths;
  final totalInterest = totalPayment - principal;

  return LoanResult(
    monthlyPayment: monthlyPayment,
    totalPayment: totalPayment,
    totalInterest: totalInterest,
  );
}
