import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/subscriptions/data/models/subscription.dart';
import 'package:finassist/features/subscriptions/data/repositories/subscription_repository.dart';

import 'support/pump_app.dart';

class _ThrowingSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<Subscription>> getSubscriptions() async {
    throw const ApiException("Couldn't connect. Please check your connection and try again.");
  }

  @override
  Future<Subscription> getSubscription(int id) => throw UnimplementedError();

  @override
  Future<Subscription> createSubscription(Map<String, dynamic> body) =>
      throw UnimplementedError();

  @override
  Future<Subscription> updateSubscription(int id, Map<String, dynamic> changes) =>
      throw UnimplementedError();

  @override
  Future<void> deleteSubscription(int id) => throw UnimplementedError();
}

Subscription _sub({
  int id = 1,
  String name = 'Netflix',
  double amount = 7000,
  SubscriptionFrequency frequency = SubscriptionFrequency.monthly,
  SubscriptionStatus status = SubscriptionStatus.active,
  SubscriptionCategory? category,
  DateTime? nextBillingDate,
}) {
  final now = DateTime(2026, 1, 1);
  return Subscription(
    id: id,
    userId: 1,
    name: name,
    amount: amount,
    currency: 'NGN',
    frequency: frequency,
    nextBillingDate: nextBillingDate ?? DateTime(2026, 10, 15),
    category: category,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Future<void> openSubscriptions(
    WidgetTester tester, {
    SubscriptionRepository? subscriptionRepository,
  }) async {
    await pumpApp(tester, subscriptionRepository: subscriptionRepository);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Subscription Tracker'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Subscription Tracker'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the real empty state, not fake sample subscriptions', (
    tester,
  ) async {
    await openSubscriptions(tester);

    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget);
  });

  testWidgets('shows an error state with retry on load failure', (tester) async {
    await openSubscriptions(
      tester,
      subscriptionRepository: _ThrowingSubscriptionRepository(),
    );

    expect(find.text('Try again'), findsOneWidget);

    // Retrying re-triggers the same failing load without crashing.
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('computes real monthly/yearly totals from active subscriptions', (
    tester,
  ) async {
    await openSubscriptions(
      tester,
      subscriptionRepository: FakeSubscriptionRepository(
        seed: [
          _sub(id: 1, name: 'Netflix', amount: 7000, status: SubscriptionStatus.active),
          _sub(id: 2, name: 'Old Gym', amount: 50000, status: SubscriptionStatus.cancelled),
        ],
      ),
    );

    // Only the active subscription counts toward the totals.
    expect(find.textContaining('₦7,000'), findsWidgets);
    expect(find.textContaining('₦84,000'), findsOneWidget);
    expect(find.text('Netflix'), findsWidgets);
  });

  testWidgets('search filters the All Subscriptions list locally by name', (
    tester,
  ) async {
    await openSubscriptions(
      tester,
      subscriptionRepository: FakeSubscriptionRepository(
        seed: [
          _sub(id: 1, name: 'Netflix'),
          _sub(id: 2, name: 'Spotify'),
        ],
      ),
    );

    await tester.tap(find.textContaining('All subscriptions'));
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'net');
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsNothing);
  });

  testWidgets('status tabs filter the All Subscriptions list', (tester) async {
    await openSubscriptions(
      tester,
      subscriptionRepository: FakeSubscriptionRepository(
        seed: [
          _sub(id: 1, name: 'Netflix', status: SubscriptionStatus.active),
          _sub(id: 2, name: 'Gym Membership', status: SubscriptionStatus.paused),
        ],
      ),
    );

    await tester.tap(find.textContaining('All subscriptions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paused (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Gym Membership'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
  });
}
