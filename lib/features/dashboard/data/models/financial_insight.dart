/// The visual/semantic category of an AI insight, used to pick an icon and
/// accent color in the presentation layer.
enum FinancialInsightType { spendingIncrease, recurringPayments, topCategory }

/// A single AI-generated observation about the user's spending, e.g.
/// "You spent 18% more on Food & Dining compared to last month."
class FinancialInsight {
  const FinancialInsight({
    required this.id,
    required this.type,
    required this.message,
    this.highlights = const [],
  });

  final String id;
  final FinancialInsightType type;
  final String message;

  /// Substrings of [message] that should be rendered with the accent color.
  final List<String> highlights;
}
