import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/budget_planner.dart';
import '../widgets/calculator_scaffold.dart';

class BudgetPlannerScreen extends ConsumerStatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  ConsumerState<BudgetPlannerScreen> createState() =>
      _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends ConsumerState<BudgetPlannerScreen> {
  final _incomeController = TextEditingController();
  BudgetSplit? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeController.text.trim());
    if (income == null || income <= 0) {
      setState(() => _result = null);
      return;
    }
    final split = calculateBudgetSplit(income);
    setState(() => _result = split);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final symbol = currencyOptionFor(
      ref.watch(preferencesControllerProvider).currency,
    ).symbol;
    return CalculatorScaffold(
      title: 'Budget Planner',
      children: [
        CalculatorField(
          label: 'Monthly income',
          controller: _incomeController,
          suffixText: symbol,
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
                  label: 'Needs (50%)',
                  value: formatCurrency(result.needs, symbol),
                ),
                CalculatorResultRow(
                  label: 'Wants (30%)',
                  value: formatCurrency(result.wants, symbol),
                ),
                CalculatorResultRow(
                  label: 'Savings (20%)',
                  value: formatCurrency(result.savings, symbol),
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
