import '../data/models/subscription.dart';

/// Pure, local filtering over an already-loaded subscription list — search
/// and filters never trigger another network request.
List<Subscription> filterSubscriptions(
  List<Subscription> subscriptions, {
  String query = '',
  SubscriptionStatus? status,
  SubscriptionCategory? category,
  SubscriptionFrequency? frequency,
  PaymentMethod? paymentMethod,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return subscriptions.where((s) {
    if (normalizedQuery.isNotEmpty &&
        !s.name.toLowerCase().contains(normalizedQuery)) {
      return false;
    }
    if (status != null && s.status != status) return false;
    if (category != null && s.category != category) return false;
    if (frequency != null && s.frequency != frequency) return false;
    if (paymentMethod != null && s.paymentMethod != paymentMethod) {
      return false;
    }
    return true;
  }).toList();
}
