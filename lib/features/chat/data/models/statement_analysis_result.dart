import 'chat_message.dart';

/// The outcome of a (mock) statement analysis: the assistant's summary
/// message plus the period it covers, so the UI can show a persistent
/// "you're chatting about this statement" context bar.
class StatementAnalysisResult {
  const StatementAnalysisResult({
    required this.message,
    required this.periodStart,
    required this.periodEnd,
  });

  final ChatMessage message;
  final DateTime periodStart;
  final DateTime periodEnd;
}
