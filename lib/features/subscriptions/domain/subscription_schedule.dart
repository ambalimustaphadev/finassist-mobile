import '../data/models/subscription.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _addMonths(DateTime date, int months) {
  return DateTime(date.year, date.month + months, date.day);
}

DateTime _increment(DateTime date, SubscriptionFrequency frequency) {
  switch (frequency) {
    case SubscriptionFrequency.weekly:
      return date.add(const Duration(days: 7));
    case SubscriptionFrequency.monthly:
      return _addMonths(date, 1);
    case SubscriptionFrequency.quarterly:
      return _addMonths(date, 3);
    case SubscriptionFrequency.semiannual:
      return _addMonths(date, 6);
    case SubscriptionFrequency.yearly:
      return DateTime(date.year + 1, date.month, date.day);
  }
}

/// Rolls [storedDate] forward by whole [frequency] increments until it
/// lands on today or later. This is purely a *display* calculation — it
/// never writes back to `next_billing_date` and never fabricates a
/// transaction/renewal history; V1 has no background job that keeps the
/// stored date current, so a subscription added months ago would otherwise
/// show a billing date in the past.
DateTime nextOccurrence(
  DateTime storedDate,
  SubscriptionFrequency frequency, {
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  var occurrence = _dateOnly(storedDate);
  var guard = 0;
  while (occurrence.isBefore(today) && guard < 1000) {
    occurrence = _increment(occurrence, frequency);
    guard++;
  }
  return occurrence;
}

/// Short relative label for a date that's today or in the future — "Today",
/// "Tomorrow", or "In N days".
String relativeCountdown(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(date);
  final days = target.difference(today).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}
