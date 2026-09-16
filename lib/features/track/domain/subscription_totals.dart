import '../data/models/subscription.dart';

/// Normalizes [subscription]'s recurring amount into a monthly-equivalent
/// figure — the display totals are computed client-side from whatever the
/// backend returns, never persisted or invented as a separate balance.
double monthlyEquivalent(Subscription subscription) {
  switch (subscription.frequency) {
    case SubscriptionFrequency.weekly:
      return subscription.amount * 52 / 12;
    case SubscriptionFrequency.monthly:
      return subscription.amount;
    case SubscriptionFrequency.quarterly:
      return subscription.amount / 3;
    case SubscriptionFrequency.semiannual:
      return subscription.amount / 6;
    case SubscriptionFrequency.yearly:
      return subscription.amount / 12;
  }
}

/// Normalizes [subscription]'s recurring amount into a yearly-equivalent
/// figure.
double yearlyEquivalent(Subscription subscription) {
  switch (subscription.frequency) {
    case SubscriptionFrequency.weekly:
      return subscription.amount * 52;
    case SubscriptionFrequency.monthly:
      return subscription.amount * 12;
    case SubscriptionFrequency.quarterly:
      return subscription.amount * 4;
    case SubscriptionFrequency.semiannual:
      return subscription.amount * 2;
    case SubscriptionFrequency.yearly:
      return subscription.amount;
  }
}

/// Sum of [monthlyEquivalent] across every **active** subscription — paused
/// and cancelled subscriptions aren't a current recurring commitment, so
/// they're excluded from the spend totals.
double totalMonthlySpend(List<Subscription> subscriptions) {
  return subscriptions
      .where((s) => s.status == SubscriptionStatus.active)
      .fold(0.0, (sum, s) => sum + monthlyEquivalent(s));
}

/// Sum of [yearlyEquivalent] across every **active** subscription.
double totalYearlySpend(List<Subscription> subscriptions) {
  return subscriptions
      .where((s) => s.status == SubscriptionStatus.active)
      .fold(0.0, (sum, s) => sum + yearlyEquivalent(s));
}
