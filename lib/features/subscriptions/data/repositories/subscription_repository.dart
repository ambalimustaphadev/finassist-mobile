import '../models/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> getSubscriptions();

  Future<Subscription> getSubscription(int id);

  Future<Subscription> createSubscription(Map<String, dynamic> body);

  Future<Subscription> updateSubscription(int id, Map<String, dynamic> changes);

  Future<void> deleteSubscription(int id);
}
