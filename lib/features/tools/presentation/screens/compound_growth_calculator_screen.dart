import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/compound_growth_calculator.dart';
import '../widgets/calculator_scaffold.dart';

class CompoundGrowthCalculatorScreen extends ConsumerStatefulWidget {
  const CompoundGrowthCalculatorScreen({super.key});

  @override
  ConsumerState<CompoundGrowthCalculatorScreen> createState() =>
      _CompoundGrowthCalculatorScreenState();
}

class _CompoundGrowthCalculatorScreenState
    extends ConsumerState<CompoundGrowthCalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _yearsController = TextEditingController();
  double? _result;

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());
    final years = int.tryParse(_yearsController.text.trim());

    if (principal == null || principal <= 0 || rate == null || years == null) {
      setState(() => _result = null);
      return;
    }

    final futureValue = calculateCompoundGrowth(
      principal: principal,
      annualInterestRatePercent: rate,
      years: years,
    );
    setState(() => _result = futureValue);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = currencyOptionFor(
      ref.watch(preferencesControllerProvider).currency,
    ).symbol;
    return CalculatorScaffold(
      title: 'Compound Growth Calculator',
      children: [
        CalculatorField(
          label: 'Principal amount',
          controller: _principalController,
          suffixText: symbol,
        ),
        CalculatorField(
          label: 'Annual interest rate',
          controller: _rateController,
          suffixText: '%',
        ),
        CalculatorField(label: 'Number of years', controller: _yearsController),
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
              label: 'Future value',
              value: formatCurrency(_result!, symbol),
              emphasize: true,
            ),
          ),
        ],
      ],
    );
  }
}
