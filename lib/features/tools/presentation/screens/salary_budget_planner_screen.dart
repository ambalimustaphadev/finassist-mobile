import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/salary_budget_planner.dart';
import '../widgets/calculator_scaffold.dart';

/// Distinct from Budget Planner: this one starts from a *gross* salary and
/// applies real payroll-style deductions (tax, pension, other) to arrive at
/// a net take-home figure, rather than allocating an already-net income
/// across spending categories.
class SalaryBudgetPlannerScreen extends ConsumerStatefulWidget {
  const SalaryBudgetPlannerScreen({super.key});

  @override
  ConsumerState<SalaryBudgetPlannerScreen> createState() =>
      _SalaryBudgetPlannerScreenState();
}

class _SalaryBudgetPlannerScreenState
    extends ConsumerState<SalaryBudgetPlannerScreen> {
  final _grossController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  final _pensionController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '0');
  SalaryBreakdown? _result;

  @override
  void dispose() {
    _grossController.dispose();
    _taxController.dispose();
    _pensionController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _calculate() {
    final gross = double.tryParse(_grossController.text.trim());
    if (gross == null || gross <= 0) {
      setState(() => _result = null);
      return;
    }
    final tax = double.tryParse(_taxController.text.trim()) ?? 0;
    final pension = double.tryParse(_pensionController.text.trim()) ?? 0;
    final other = double.tryParse(_otherController.text.trim()) ?? 0;

    final breakdown = calculateNetSalary(
      grossSalary: gross,
      taxPercent: tax,
      pensionPercent: pension,
      otherDeductionsPercent: other,
    );
    setState(() => _result = breakdown);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final symbol = currencyOptionFor(
      ref.watch(preferencesControllerProvider).currency,
    ).symbol;
    return CalculatorScaffold(
      title: 'Salary/Budget Planner',
      children: [
        CalculatorField(
          label: 'Gross monthly salary',
          controller: _grossController,
          suffixText: symbol,
        ),
        CalculatorField(
          label: 'Tax rate',
          controller: _taxController,
          suffixText: '%',
        ),
        CalculatorField(
          label: 'Pension contribution',
          controller: _pensionController,
          suffixText: '%',
        ),
        CalculatorField(
          label: 'Other deductions',
          controller: _otherController,
          suffixText: '%',
        ),
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
                  label: 'Tax',
                  value: '- ${formatCurrency(result.tax, symbol)}',
                ),
                CalculatorResultRow(
                  label: 'Pension',
                  value: '- ${formatCurrency(result.pension, symbol)}',
                ),
                CalculatorResultRow(
                  label: 'Other deductions',
                  value: '- ${formatCurrency(result.otherDeductions, symbol)}',
                ),
                Divider(color: context.colors.borderSubtle),
                CalculatorResultRow(
                  label: 'Net (take-home) salary',
                  value: formatCurrency(result.net, symbol),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
