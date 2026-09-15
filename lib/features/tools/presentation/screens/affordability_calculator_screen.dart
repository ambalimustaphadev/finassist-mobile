import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/affordability_calculator.dart';
import '../providers/tools_activity.dart';
import '../widgets/calculator_scaffold.dart';

class AffordabilityCalculatorScreen extends ConsumerStatefulWidget {
  const AffordabilityCalculatorScreen({super.key});

  @override
  ConsumerState<AffordabilityCalculatorScreen> createState() =>
      _AffordabilityCalculatorScreenState();
}

class _AffordabilityCalculatorScreenState
    extends ConsumerState<AffordabilityCalculatorScreen> {
  final _incomeController = TextEditingController();
  final _debtController = TextEditingController(text: '0');
  double? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeController.text.trim());
    final debt = double.tryParse(_debtController.text.trim()) ?? 0;

    if (income == null || income <= 0) {
      setState(() => _result = null);
      return;
    }

    final max = calculateMaxAffordablePayment(
      monthlyIncome: income,
      existingMonthlyDebt: debt,
    );
    setState(() => _result = max);
    final symbol = currencyOptionFor(
      ref.read(preferencesControllerProvider).currency,
    ).symbol;
    recordCalculation(
      ref,
      type: 'affordability_calculation',
      toolName: 'Affordability Calculator',
      summary:
          'Up to ${formatCurrency(max, symbol)}/month on '
          '${formatCurrency(income, symbol)} income',
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = currencyOptionFor(
      ref.watch(preferencesControllerProvider).currency,
    ).symbol;
    return CalculatorScaffold(
      title: 'Affordability Calculator',
      children: [
        CalculatorField(
          label: 'Monthly income',
          controller: _incomeController,
          suffixText: symbol,
        ),
        CalculatorField(
          label: 'Existing monthly debt payments',
          controller: _debtController,
          suffixText: symbol,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: _calculate,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Calculate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                CalculatorResultRow(
                  label: 'Max additional monthly payment',
                  value: formatCurrency(_result!, symbol),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Based on a standard 36% debt-to-income guideline.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
