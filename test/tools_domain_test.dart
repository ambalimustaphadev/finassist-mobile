import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/tools/domain/affordability_calculator.dart';
import 'package:finassist/features/tools/domain/budget_planner.dart';
import 'package:finassist/features/tools/domain/compound_growth_calculator.dart';
import 'package:finassist/features/tools/domain/currency_converter.dart';
import 'package:finassist/features/tools/domain/loan_calculator.dart';
import 'package:finassist/features/tools/domain/salary_budget_planner.dart';
import 'package:finassist/features/tools/domain/savings_calculator.dart';

void main() {
  group('calculateBudgetSplit', () {
    test('splits income 50/30/20 by default', () {
      final split = calculateBudgetSplit(300000);

      expect(split.needs, 150000);
      expect(split.wants, 90000);
      expect(split.savings, 60000);
    });

    test('honors custom percentages', () {
      final split = calculateBudgetSplit(
        100000,
        needsPercent: 60,
        wantsPercent: 20,
        savingsPercent: 20,
      );

      expect(split.needs, 60000);
      expect(split.wants, 20000);
      expect(split.savings, 20000);
    });
  });

  group('calculateFutureSavings', () {
    test('with zero interest, it is just the sum of contributions', () {
      final result = calculateFutureSavings(
        monthlyContribution: 10000,
        annualInterestRatePercent: 0,
        months: 12,
        startingBalance: 5000,
      );

      expect(result, 5000 + 10000 * 12);
    });

    test('with interest, it grows beyond the plain sum of contributions', () {
      final noInterest = calculateFutureSavings(
        monthlyContribution: 10000,
        annualInterestRatePercent: 0,
        months: 12,
      );
      final withInterest = calculateFutureSavings(
        monthlyContribution: 10000,
        annualInterestRatePercent: 12,
        months: 12,
      );

      expect(withInterest, greaterThan(noInterest));
    });

    test('a non-positive term returns just the starting balance', () {
      final result = calculateFutureSavings(
        monthlyContribution: 10000,
        annualInterestRatePercent: 5,
        months: 0,
        startingBalance: 20000,
      );

      expect(result, 20000);
    });
  });

  group('calculateLoan', () {
    test('with zero interest, the monthly payment is principal / months', () {
      final result = calculateLoan(
        principal: 120000,
        annualInterestRatePercent: 0,
        termMonths: 12,
      );

      expect(result.monthlyPayment, 10000);
      expect(result.totalInterest, 0);
      expect(result.totalPayment, 120000);
    });

    test('with interest, total payment exceeds the principal', () {
      final result = calculateLoan(
        principal: 1000000,
        annualInterestRatePercent: 18,
        termMonths: 24,
      );

      expect(result.totalPayment, greaterThan(1000000));
      expect(result.totalInterest, greaterThan(0));
      expect(result.totalPayment, closeTo(result.monthlyPayment * 24, 0.01));
    });

    test('a zero/negative term never divides by zero or crashes', () {
      final result = calculateLoan(
        principal: 100000,
        annualInterestRatePercent: 10,
        termMonths: 0,
      );

      expect(result.monthlyPayment, 0);
      expect(result.totalPayment, 0);
      expect(result.totalInterest, 0);
    });
  });

  group('calculateCompoundGrowth', () {
    test('a lump sum with no interest never changes', () {
      final result = calculateCompoundGrowth(
        principal: 50000,
        annualInterestRatePercent: 0,
        years: 5,
      );

      expect(result, 50000);
    });

    test('compounds upward over time at a positive rate', () {
      final oneYear = calculateCompoundGrowth(
        principal: 100000,
        annualInterestRatePercent: 10,
        years: 1,
      );
      final fiveYears = calculateCompoundGrowth(
        principal: 100000,
        annualInterestRatePercent: 10,
        years: 5,
      );

      expect(oneYear, greaterThan(100000));
      expect(fiveYears, greaterThan(oneYear));
    });
  });

  group('calculateMaxAffordablePayment', () {
    test('caps total debt at the debt-to-income ratio', () {
      final result = calculateMaxAffordablePayment(
        monthlyIncome: 500000,
        existingMonthlyDebt: 50000,
      );

      // 36% of 500,000 = 180,000; minus the existing 50,000 debt.
      expect(result, 130000);
    });

    test(
      'never goes negative when existing debt already exceeds the ratio',
      () {
        final result = calculateMaxAffordablePayment(
          monthlyIncome: 200000,
          existingMonthlyDebt: 400000,
        );

        expect(result, 0);
      },
    );
  });

  group('calculateNetSalary', () {
    test('subtracts each deduction from the gross amount', () {
      final result = calculateNetSalary(
        grossSalary: 500000,
        taxPercent: 10,
        pensionPercent: 8,
        otherDeductionsPercent: 2,
      );

      expect(result.tax, 50000);
      expect(result.pension, 40000);
      expect(result.otherDeductions, 10000);
      expect(result.net, 400000);
    });

    test('net is never negative even with unrealistic deduction totals', () {
      final result = calculateNetSalary(
        grossSalary: 100000,
        taxPercent: 60,
        pensionPercent: 30,
        otherDeductionsPercent: 30,
      );

      expect(result.net, 0);
    });
  });

  group('convertAmount', () {
    test('multiplies the amount by the given rate', () {
      expect(convertAmount(100, 1550.25), closeTo(155025, 0.01));
    });
  });
}
