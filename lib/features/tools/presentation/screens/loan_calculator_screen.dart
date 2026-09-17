import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/loan_calculator.dart';
import '../providers/tools_activity.dart';
import '../widgets/calculator_scaffold.dart';

class LoanCalculatorScreen extends ConsumerStatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  ConsumerState<LoanCalculatorScreen> createState() =>
      _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends ConsumerState<LoanCalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();
  LoanResult? _result;

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());
    final term = int.tryParse(_termController.text.trim());

    if (principal == null || principal <= 0 || rate == null || term == null) {
      setState(() => _result = null);
      return;
    }

    final result = calculateLoan(
      principal: principal,
      annualInterestRatePercent: rate,
      termMonths: term,
    );
    setState(() => _result = result);
    final symbol = currencyOptionFor(
      ref.read(preferencesControllerProvider).currency,
    ).symbol;
    recordCalculation(
      ref,
      type: 'loan_calculation',
      toolName: 'Loan Calculator',
      summary:
          '${formatCurrency(principal, symbol)} over $term months at $rate% → '
          '${formatCurrency(result.monthlyPayment, symbol)}/month',
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final symbol = currencyOptionFor(
      ref.watch(preferencesControllerProvider).currency,
    ).symbol;
    return CalculatorScaffold(
      title: 'Loan Calculator',
      children: [
        CalculatorField(
          label: 'Loan amount',
          controller: _principalController,
          suffixText: symbol,
        ),
        CalculatorField(
          label: 'Annual interest rate',
          controller: _rateController,
          suffixText: '%',
        ),
        CalculatorField(label: 'Term (months)', controller: _termController),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: context.colors.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: _calculate,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Calculate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textOnAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                CalculatorResultRow(
                  label: 'Monthly payment',
                  value: formatCurrency(result.monthlyPayment, symbol),
                  emphasize: true,
                ),
                CalculatorResultRow(
                  label: 'Total interest',
                  value: formatCurrency(result.totalInterest, symbol),
                ),
                CalculatorResultRow(
                  label: 'Total repayment',
                  value: formatCurrency(result.totalPayment, symbol),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
