import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/savings_calculator.dart';
import '../providers/tools_activity.dart';
import '../widgets/calculator_scaffold.dart';

class SavingsCalculatorScreen extends ConsumerStatefulWidget {
  const SavingsCalculatorScreen({super.key});

  @override
  ConsumerState<SavingsCalculatorScreen> createState() =>
      _SavingsCalculatorScreenState();
}

class _SavingsCalculatorScreenState
    extends ConsumerState<SavingsCalculatorScreen> {
  final _startingController = TextEditingController(text: '0');
  final _contributionController = TextEditingController();
  final _rateController = TextEditingController(text: '0');
  final _monthsController = TextEditingController();
  double? _result;

  @override
  void dispose() {
    _startingController.dispose();
    _contributionController.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final starting = double.tryParse(_startingController.text.trim()) ?? 0;
    final contribution = double.tryParse(_contributionController.text.trim());
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    final months = int.tryParse(_monthsController.text.trim());

    if (contribution == null || months == null || months <= 0) {
      setState(() => _result = null);
      return;
    }

    final futureValue = calculateFutureSavings(
      monthlyContribution: contribution,
      annualInterestRatePercent: rate,
      months: months,
      startingBalance: starting,
    );
    setState(() => _result = futureValue);
    final symbol = currencyOptionFor(
      ref.read(preferencesControllerProvider).currency,
    ).symbol;
    recordCalculation(
      ref,
      type: 'savings_calculation',
      toolName: 'Savings Calculator',
      summary:
          'Projected ${formatCurrency(futureValue, symbol)} after $months months',
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = currencyOptionFor(
      ref.watch(preferencesControllerProvider).currency,
    ).symbol;
    return CalculatorScaffold(
      title: 'Savings Calculator',
      children: [
        CalculatorField(
          label: 'Starting balance',
          controller: _startingController,
          suffixText: symbol,
        ),
        CalculatorField(
          label: 'Monthly contribution',
          controller: _contributionController,
          suffixText: symbol,
        ),
        CalculatorField(
          label: 'Annual interest rate',
          controller: _rateController,
          suffixText: '%',
        ),
        CalculatorField(
          label: 'Number of months',
          controller: _monthsController,
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
            child: CalculatorResultRow(
              label: 'Projected balance',
              value: formatCurrency(_result!, symbol),
              emphasize: true,
            ),
          ),
        ],
      ],
    );
  }
}
