/// A recurring subscription/bill detected on the statement.
class RecurringPayment {
  const RecurringPayment({
    required this.name,
    required this.amount,
    required this.frequency,
  });

  final String name;
  final double amount;
  final String frequency;
}
