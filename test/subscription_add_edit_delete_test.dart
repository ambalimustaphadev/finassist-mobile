import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/subscriptions/data/models/subscription.dart';

import 'support/pump_app.dart';

Subscription _sub({
  int id = 1,
  String name = 'Netflix',
  double amount = 7000,
  SubscriptionStatus status = SubscriptionStatus.active,
}) {
  final now = DateTime(2026, 1, 1);
  return Subscription(
    id: id,
    userId: 1,
    name: name,
    amount: amount,
    currency: 'NGN',
    frequency: SubscriptionFrequency.monthly,
    nextBillingDate: DateTime(2026, 10, 15),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _openSubscriptions(
  WidgetTester tester, {
  FakeSubscriptionRepository? repository,
}) async {
  await pumpApp(tester, subscriptionRepository: repository);
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

/// Confirms the default-initialDate date picker (today), matching the app's
/// only date-picker usage — no calendar navigation needed since the field
/// starts unset and `showDatePicker`'s `initialDate` defaults to today.
Future<void> _pickDate(WidgetTester tester) async {
  await tester.tap(find.text('Select date'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'full create flow: basic info -> details -> review -> success -> detail',
    (tester) async {
      await _openSubscriptions(tester, repository: FakeSubscriptionRepository());

      // Empty state's CTA starts the wizard.
      await tester.tap(find.text('Add subscription'));
      await tester.pumpAndSettle();

      // Basic info.
      await tester.enterText(find.byType(TextField).at(0), 'Netflix');
      await tester.enterText(find.byType(TextField).at(1), '7000');
      await _pickDate(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Details (all optional) — skip straight through.
      expect(find.text('Additional details (optional)'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Review.
      expect(find.text('Review subscription'), findsOneWidget);
      expect(find.text('Netflix'), findsWidgets);
      await tester.tap(find.text('Save subscription'));
      await tester.pumpAndSettle();

      // Success — only shown once the fake repository actually resolved.
      expect(find.text('Subscription added'), findsOneWidget);
      expect(
        find.text('Netflix has been added to your subscriptions.'),
        findsOneWidget,
      );

      await tester.tap(find.text('View subscription'));
      await tester.pumpAndSettle();

      expect(find.text('Subscription'), findsOneWidget); // detail app bar
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.textContaining('₦7,000'), findsWidgets);
    },
  );

  testWidgets('validation blocks Continue until required basic fields are set', (
    tester,
  ) async {
    await _openSubscriptions(tester, repository: FakeSubscriptionRepository());
    await tester.tap(find.text('Add subscription'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Still on basic info — never silently advances on invalid input.
    expect(find.text('Enter a subscription name.'), findsOneWidget);
    expect(find.text('Enter a valid amount.'), findsOneWidget);
    expect(find.text('Select the next billing date.'), findsOneWidget);
  });

  testWidgets('edit flow preserves untouched values and applies changes', (
    tester,
  ) async {
    await _openSubscriptions(
      tester,
      repository: FakeSubscriptionRepository(seed: [_sub()]),
    );

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Existing values are preserved, not blanked out.
    expect(find.widgetWithText(TextField, 'Netflix'), findsOneWidget);
    expect(find.widgetWithText(TextField, '7000'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '7000'), '9000');
    await tester.dragUntilVisible(
      find.text('Save changes'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('₦9,000'), findsWidgets);
  });

  testWidgets('delete requires confirmation and only removes after it resolves', (
    tester,
  ) async {
    await _openSubscriptions(
      tester,
      repository: FakeSubscriptionRepository(seed: [_sub()]),
    );

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Delete subscription?'), findsOneWidget);

    // Cancelling the dialog keeps the subscription intact.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Netflix'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete subscription'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No subscriptions yet'), findsOneWidget);
  });

  testWidgets('pause and cancel update the status badge without deleting the row', (
    tester,
  ) async {
    await _openSubscriptions(
      tester,
      repository: FakeSubscriptionRepository(seed: [_sub()]),
    );

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    // Already paused, so "Pause subscription" is no longer offered.
    expect(find.text('Pause subscription'), findsNothing);
    await tester.tap(find.text('Cancel subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelled'), findsOneWidget);
  });
}
