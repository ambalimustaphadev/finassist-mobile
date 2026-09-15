import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/activity/data/repositories/activity_log_repository.dart';
import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';

import 'support/pump_app.dart';

void main() {
  Future<void> openTools(
    WidgetTester tester, {
    ActivityLogRepository? activityLogRepository,
  }) async {
    await pumpApp(
      tester,
      activityLogRepository: activityLogRepository,
      overrides: [
        statementFilePickerServiceProvider.overrideWithValue(
          FakeStatementFilePickerService(),
        ),
        chatRepositoryProvider.overrideWithValue(MockChatRepository()),
      ],
    );
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tools'));
    await tester.pumpAndSettle();
  }

  /// The 2-column grid is taller than the default test viewport, so later
  /// rows aren't built until scrolled into view — same as a real phone
  /// scrolling to see the rest of the tools.
  Future<void> scrollToTool(WidgetTester tester, String title) async {
    await tester.dragUntilVisible(
      find.text(title),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
  }

  testWidgets('lists all 7 real calculators', (tester) async {
    await openTools(tester);

    expect(find.text('Budget Planner'), findsOneWidget);
    expect(find.text('Savings Calculator'), findsOneWidget);
    await scrollToTool(tester, 'Loan Calculator');
    expect(find.text('Loan Calculator'), findsOneWidget);
    await scrollToTool(tester, 'Currency Converter');
    expect(find.text('Currency Converter'), findsOneWidget);
    await scrollToTool(tester, 'Affordability Calculator');
    expect(find.text('Affordability Calculator'), findsOneWidget);
    await scrollToTool(tester, 'Investment Calculator');
    expect(find.text('Investment Calculator'), findsOneWidget);
    await scrollToTool(tester, 'Salary/Budget Planner');
    expect(find.text('Salary/Budget Planner'), findsOneWidget);
  });

  testWidgets(
    'the Loan Calculator computes a real amortized monthly payment, not a '
    'fabricated number, and logs it via the activity log repository',
    (tester) async {
      final activityLog = FakeActivityLogRepository();
      await openTools(tester, activityLogRepository: activityLog);

      await scrollToTool(tester, 'Loan Calculator');
      await tester.tap(find.text('Loan Calculator'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1200000'); // loan amount
      await tester.enterText(fields.at(1), '0'); // 0% interest for exact math
      await tester.enterText(fields.at(2), '12'); // term months

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // 1,200,000 / 12 = 100,000/month, zero interest.
      expect(find.textContaining('₦100,000'), findsOneWidget);
      expect(find.text('Total interest'), findsOneWidget);

      // There's no Activity feed screen anymore (the dashboard/activity
      // display was removed), but the calculator still logs the run via
      // the same repository real calculators post to — verify that
      // directly instead of through a UI screen.
      final entries = await activityLog.getActivity();
      expect(entries, hasLength(1));
      expect(entries.first.title, 'Loan Calculator');
      expect(entries.first.description, contains('₦1,200,000 over 12 months'));
    },
  );
}
