/// Breaks a gross salary down into its deductions and the resulting net
/// (take-home) amount — a plain percentage calculation, not a real tax
/// engine, so the user supplies whatever rates actually apply to them.
class SalaryBreakdown {
  const SalaryBreakdown({
    required this.gross,
    required this.tax,
    required this.pension,
    required this.otherDeductions,
    required this.net,
  });

  final double gross;
  final double tax;
  final double pension;
  final double otherDeductions;
  final double net;
}

SalaryBreakdown calculateNetSalary({
  required double grossSalary,
  double taxPercent = 0,
  double pensionPercent = 0,
  double otherDeductionsPercent = 0,
}) {
  final tax = grossSalary * taxPercent / 100;
  final pension = grossSalary * pensionPercent / 100;
  final other = grossSalary * otherDeductionsPercent / 100;
  final net = grossSalary - tax - pension - other;

  return SalaryBreakdown(
    gross: grossSalary,
    tax: tax,
    pension: pension,
    otherDeductions: other,
    net: net < 0 ? 0 : net,
  );
}
