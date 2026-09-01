/// An uploaded bank statement that the AI assistant can answer questions
/// about. Later this will be populated from a real upload + parsing backend.
class BankStatement {
  const BankStatement({
    required this.fileName,
    required this.periodStart,
    required this.periodEnd,
    required this.institution,
  });

  final String fileName;
  final String institution;
  final DateTime periodStart;
  final DateTime periodEnd;
}
