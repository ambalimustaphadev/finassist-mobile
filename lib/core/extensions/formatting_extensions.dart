import 'package:intl/intl.dart';

/// Formats [amount] with an arbitrary currency [symbol] — used by the
/// Tools calculators, whose currency preference is chosen per-calculation
/// rather than fixed. Plain thousands separators, no locale-specific
/// currency rules.
String formatCurrency(double amount, String symbol) {
  final formatter = NumberFormat('#,##0');
  return '$symbol${formatter.format(amount)}';
}

extension DateFormatting on DateTime {
  String toTimeOfDay() => DateFormat('h:mm a').format(this);

  /// Short, human label for a conversation-list timestamp: "Today",
  /// "Yesterday", the weekday name within the last week, or "Aug 18"
  /// (with the year appended once it's not this one).
  String toRelativeConversationDate({DateTime? now}) {
    final today = now ?? DateTime.now();
    final that = DateTime(year, month, day);
    final current = DateTime(today.year, today.month, today.day);
    final difference = current.difference(that).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference > 1 && difference < 7) {
      return DateFormat('EEEE').format(this);
    }
    if (year == today.year) return DateFormat('MMM d').format(this);
    return DateFormat('MMM d, yyyy').format(this);
  }
}

/// Formats a byte count as a short human-readable size, e.g. "1.2 MB".
/// Returns an empty string when [bytes] is unknown or non-positive.
String formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const kb = 1024;
  const mb = kb * 1024;
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
  return '$bytes B';
}
