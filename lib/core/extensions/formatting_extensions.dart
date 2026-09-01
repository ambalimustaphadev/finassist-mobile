import 'package:intl/intl.dart';

/// Formatting helpers shared across dashboard and chat features so currency
/// and date rendering stays consistent everywhere.
extension CurrencyFormatting on num {
  String toNaira({bool compact = false}) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  String toPercentage({int decimals = 1}) => '${toStringAsFixed(decimals)}%';
}

extension DateFormatting on DateTime {
  String toMonthDayYear() => DateFormat('MMM d, yyyy').format(this);

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

/// Formats a statement/spending period as "May 1 – May 31, 2024".
String formatDateRange(DateTime start, DateTime end) {
  final startLabel = DateFormat('MMM d').format(start);
  final endLabel = DateFormat('MMM d, yyyy').format(end);
  return '$startLabel – $endLabel';
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
