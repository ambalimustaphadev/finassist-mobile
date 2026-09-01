/// Aggregate spending figures for a period, shown at the top of the
/// spending overview card.
class SpendingSummary {
  const SpendingSummary({
    required this.totalAmount,
    required this.comparisonPercentage,
    required this.periodLabel,
    required this.comparisonLabel,
  });

  final double totalAmount;

  /// Positive means spending increased vs. the comparison period.
  final double comparisonPercentage;
  final String periodLabel;
  final String comparisonLabel;
}
