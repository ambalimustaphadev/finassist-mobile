import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/notifications/data/models/notification.dart';

import 'support/pump_app.dart';

/// The notification bell now lives on Profile's app bar (the old
/// dashboard header it used to live on no longer exists) — reached via
/// the bottom-nav "Profile" tab, not a CTA on the landing screen.
void main() {
  Finder bellIcon() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.notifications_none_rounded),
  );

  testWidgets('no unread notifications means no dot on the bell icon', (
    tester,
  ) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(bellIcon());
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up"), findsOneWidget);
  });

  testWidgets(
    'a real unread notification shows the dot, and tapping it marks it read',
    (tester) async {
      final repository = FakeNotificationRepository(
        seed: [
          AppNotification(
            id: 1,
            type: 'goal_overdue',
            title: 'Vacation fund is overdue',
            read: false,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await pumpApp(tester, notificationRepository: repository);
      await loginWithDemoAccount(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(bellIcon());
      await tester.pumpAndSettle();

      expect(find.text('Vacation fund is overdue'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);

      await tester.tap(find.text('Vacation fund is overdue'));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsNothing);
    },
  );
}
