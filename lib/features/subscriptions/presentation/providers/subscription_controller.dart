import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/api_subscription_repository.dart';
import '../../data/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return ApiSubscriptionRepository(baseUrl: apiBaseUrl);
});

/// Rebuilt whenever the authenticated user changes, same pattern as every
/// other per-user controller in this app.
final subscriptionsControllerProvider =
    StateNotifierProvider<SubscriptionsController, SubscriptionsState>((ref) {
      ref.watch(authControllerProvider.select((state) => state.user?.id));
      return SubscriptionsController(ref.watch(subscriptionRepositoryProvider));
    });

enum SubscriptionsLoadStatus { loading, loaded, error }

class SubscriptionsState {
  const SubscriptionsState({
    this.status = SubscriptionsLoadStatus.loading,
    this.subscriptions = const [],
    this.loadError,
  });

  final SubscriptionsLoadStatus status;
  final List<Subscription> subscriptions;
  final String? loadError;

  SubscriptionsState copyWith({
    SubscriptionsLoadStatus? status,
    List<Subscription>? subscriptions,
    String? loadError,
    bool clearLoadError = false,
  }) {
    return SubscriptionsState(
      status: status ?? this.status,
      subscriptions: subscriptions ?? this.subscriptions,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
    );
  }
}

/// Coordinates the real, backend-authoritative subscription list — an empty
/// list is the honest default for a brand-new account, never seeded with
/// sample data. Create/update/delete only touch local state after the
/// backend call actually resolves, and let [ApiException] propagate so
/// forms can show their own inline error and keep the user's entered
/// values.
class SubscriptionsController extends StateNotifier<SubscriptionsState> {
  SubscriptionsController(this._repository) : super(const SubscriptionsState()) {
    _load();
  }

  final SubscriptionRepository _repository;

  Future<void> _load() async {
    state = state.copyWith(
      status: SubscriptionsLoadStatus.loading,
      clearLoadError: true,
    );
    try {
      final subscriptions = await _repository.getSubscriptions();
      state = state.copyWith(
        status: SubscriptionsLoadStatus.loaded,
        subscriptions: subscriptions,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: SubscriptionsLoadStatus.error,
        loadError: e.message,
      );
    }
  }

  Future<void> refresh() => _load();

  Future<Subscription> create(Map<String, dynamic> body) async {
    final created = await _repository.createSubscription(body);
    state = state.copyWith(subscriptions: [...state.subscriptions, created]);
    return created;
  }

  Future<Subscription> update(int id, Map<String, dynamic> changes) async {
    final updated = await _repository.updateSubscription(id, changes);
    state = state.copyWith(
      subscriptions: [
        for (final s in state.subscriptions) if (s.id == id) updated else s,
      ],
    );
    return updated;
  }

  Future<void> delete(int id) async {
    await _repository.deleteSubscription(id);
    state = state.copyWith(
      subscriptions: [
        for (final s in state.subscriptions) if (s.id != id) s,
      ],
    );
  }
}
