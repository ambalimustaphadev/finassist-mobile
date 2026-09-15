import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/subscriptions/data/models/subscription.dart';
import 'package:finassist/features/subscriptions/domain/subscription_brand.dart';
import 'package:finassist/features/subscriptions/domain/subscription_filter.dart';
import 'package:finassist/features/subscriptions/domain/subscription_schedule.dart';
import 'package:finassist/features/subscriptions/domain/subscription_totals.dart';

Subscription _sub({
  int id = 1,
  String name = 'Netflix',
  double amount = 1200,
  SubscriptionFrequency frequency = SubscriptionFrequency.monthly,
  SubscriptionStatus status = SubscriptionStatus.active,
  SubscriptionCategory? category,
  PaymentMethod? paymentMethod,
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
    nextBillingDate: nextBillingDate ?? DateTime(2026, 1, 15),
    category: category,
    paymentMethod: paymentMethod,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('monthlyEquivalent / yearlyEquivalent', () {
    test('weekly', () {
      final s = _sub(amount: 100, frequency: SubscriptionFrequency.weekly);
      expect(monthlyEquivalent(s), closeTo(100 * 52 / 12, 0.001));
      expect(yearlyEquivalent(s), closeTo(100 * 52, 0.001));
    });

    test('monthly', () {
      final s = _sub(amount: 1200, frequency: SubscriptionFrequency.monthly);
      expect(monthlyEquivalent(s), 1200);
      expect(yearlyEquivalent(s), 1200 * 12);
    });

    test('quarterly', () {
      final s = _sub(amount: 3000, frequency: SubscriptionFrequency.quarterly);
      expect(monthlyEquivalent(s), closeTo(1000, 0.001));
      expect(yearlyEquivalent(s), 12000);
    });

    test('semiannual', () {
      final s = _sub(amount: 6000, frequency: SubscriptionFrequency.semiannual);
      expect(monthlyEquivalent(s), closeTo(1000, 0.001));
      expect(yearlyEquivalent(s), 12000);
    });

    test('yearly', () {
      final s = _sub(amount: 12000, frequency: SubscriptionFrequency.yearly);
      expect(monthlyEquivalent(s), 1000);
      expect(yearlyEquivalent(s), 12000);
    });
  });

  group('totalMonthlySpend / totalYearlySpend', () {
    test('excludes paused and cancelled subscriptions', () {
      final subscriptions = [
        _sub(id: 1, amount: 1000, status: SubscriptionStatus.active),
        _sub(id: 2, amount: 5000, status: SubscriptionStatus.paused),
        _sub(id: 3, amount: 9000, status: SubscriptionStatus.cancelled),
      ];

      expect(totalMonthlySpend(subscriptions), 1000);
      expect(totalYearlySpend(subscriptions), 12000);
    });
  });

  group('nextOccurrence', () {
    test('a future date is returned unchanged', () {
      final result = nextOccurrence(
        DateTime(2026, 12, 25),
        SubscriptionFrequency.monthly,
        now: DateTime(2026, 9, 15),
      );
      expect(result, DateTime(2026, 12, 25));
    });

    test('rolls a past monthly date forward to the next occurrence', () {
      final result = nextOccurrence(
        DateTime(2026, 1, 15),
        SubscriptionFrequency.monthly,
        now: DateTime(2026, 9, 15),
      );
      expect(result, DateTime(2026, 9, 15));
    });

    test('rolls a past weekly date forward', () {
      final result = nextOccurrence(
        DateTime(2026, 9, 1),
        SubscriptionFrequency.weekly,
        now: DateTime(2026, 9, 15),
      );
      expect(result.isBefore(DateTime(2026, 9, 15)), isFalse);
      expect(result.difference(DateTime(2026, 9, 1)).inDays % 7, 0);
    });
  });

  group('relativeCountdown', () {
    final now = DateTime(2026, 9, 15);

    test('today', () {
      expect(relativeCountdown(DateTime(2026, 9, 15), now: now), 'Today');
    });

    test('tomorrow', () {
      expect(relativeCountdown(DateTime(2026, 9, 16), now: now), 'Tomorrow');
    });

    test('in N days', () {
      expect(relativeCountdown(DateTime(2026, 9, 21), now: now), 'In 6 days');
    });
  });

  group('filterSubscriptions', () {
    final subscriptions = [
      _sub(id: 1, name: 'Netflix', status: SubscriptionStatus.active, category: SubscriptionCategory.entertainment, frequency: SubscriptionFrequency.monthly),
      _sub(id: 2, name: 'Spotify', status: SubscriptionStatus.paused, category: SubscriptionCategory.entertainment, frequency: SubscriptionFrequency.monthly),
      _sub(id: 3, name: 'Adobe Creative Cloud', status: SubscriptionStatus.active, category: SubscriptionCategory.software, frequency: SubscriptionFrequency.yearly),
    ];

    test('case-insensitive name search', () {
      final result = filterSubscriptions(subscriptions, query: 'netflix');
      expect(result.map((s) => s.id), [1]);
    });

    test('status filtering', () {
      final result = filterSubscriptions(subscriptions, status: SubscriptionStatus.paused);
      expect(result.map((s) => s.id), [2]);
    });

    test('category filtering', () {
      final result = filterSubscriptions(subscriptions, category: SubscriptionCategory.software);
      expect(result.map((s) => s.id), [3]);
    });

    test('frequency filtering', () {
      final result = filterSubscriptions(subscriptions, frequency: SubscriptionFrequency.yearly);
      expect(result.map((s) => s.id), [3]);
    });

    test('combines query and status', () {
      final result = filterSubscriptions(
        subscriptions,
        query: 'a',
        status: SubscriptionStatus.active,
      );
      expect(result.map((s) => s.id), [3]);
    });
  });

  group('resolveIconAsset (brand resolution)', () {
    test('Netflix, Netflix Premium, Netflix Nigeria all resolve the same', () {
      final base = resolveIconAsset(name: 'Netflix');
      expect(resolveIconAsset(name: 'Netflix Premium'), base);
      expect(resolveIconAsset(name: 'Netflix Nigeria'), base);
      expect(base, contains('Netflix'));
    });

    test('unknown name with a known category falls back to the category asset', () {
      final asset = resolveIconAsset(
        name: 'My Gym App',
        category: SubscriptionCategory.fitness,
      );
      expect(asset, 'assets/subscription_categories/fitness.png');
    });

    test('unknown name with no category falls back to "other"', () {
      final asset = resolveIconAsset(name: 'Some Random Service');
      expect(asset, 'assets/subscription_categories/other.png');
    });

    test('iCloud+ normalizes the trailing plus sign', () {
      final asset = resolveIconAsset(name: 'iCloud+');
      expect(asset, 'assets/brands/iCloud.png');
    });
  });
}
