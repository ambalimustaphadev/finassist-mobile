import '../../../../core/network/api_client.dart';
import '../models/subscription.dart';
import 'subscription_repository.dart';

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository({required String baseUrl, ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  @override
  Future<List<Subscription>> getSubscriptions() async {
    final items = await _client.getList('/api/subscriptions');
    return items
        .map((item) => Subscription.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Subscription> getSubscription(int id) async {
    final json = await _client.get('/api/subscriptions/$id');
    return Subscription.fromJson(json);
  }

  @override
  Future<Subscription> createSubscription(Map<String, dynamic> body) async {
    final json = await _client.post('/api/subscriptions', body);
    return Subscription.fromJson(json);
  }

  @override
  Future<Subscription> updateSubscription(
    int id,
    Map<String, dynamic> changes,
  ) async {
    final json = await _client.patch('/api/subscriptions/$id', changes);
    return Subscription.fromJson(json);
  }

  @override
  Future<void> deleteSubscription(int id) {
    return _client.delete('/api/subscriptions/$id');
  }
}
