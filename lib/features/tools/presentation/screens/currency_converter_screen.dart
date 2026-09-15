import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/fx_rate_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/currency_converter.dart';
import '../providers/tools_activity.dart';
import '../widgets/calculator_scaffold.dart';

enum _ConversionStatus { idle, loading, success, error }

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState
    extends ConsumerState<CurrencyConverterScreen> {
  final _amountController = TextEditingController(text: '1');
  final _fromController = TextEditingController(text: 'USD');
  final _toController = TextEditingController(text: 'NGN');
  final _manualRateController = TextEditingController();

  _ConversionStatus _status = _ConversionStatus.idle;
  double? _result;
  double? _rateUsed;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text.trim());
    final from = _fromController.text.trim().toUpperCase();
    final to = _toController.text.trim().toUpperCase();

    if (amount == null || from.isEmpty || to.isEmpty) {
      setState(() {
        _status = _ConversionStatus.error;
        _errorMessage = 'Enter a valid amount and both currency codes.';
      });
      return;
    }

    setState(() {
      _status = _ConversionStatus.loading;
      _errorMessage = null;
    });

    try {
      final rates = await ref.read(fxRateServiceProvider).getRates(from);
      final rate = rates.rateFor(to);
      if (rate == null) {
        setState(() {
          _status = _ConversionStatus.error;
          _errorMessage =
              "Couldn't find a rate for $to. Try entering a rate manually.";
        });
        return;
      }
      final converted = convertAmount(amount, rate);
      setState(() {
        _status = _ConversionStatus.success;
        _result = converted;
        _rateUsed = rate;
      });
      recordCalculation(
        ref,
        type: 'currency_conversion',
        toolName: 'Currency Converter',
        summary:
            '${amount.toStringAsFixed(2)} $from → '
            '${converted.toStringAsFixed(2)} $to',
      );
    } on FxRateServiceException catch (e) {
      setState(() {
        _status = _ConversionStatus.error;
        _errorMessage = '${e.message} Try entering a rate manually below.';
      });
    }
  }

  void _convertManually() {
    final amount = double.tryParse(_amountController.text.trim());
    final rate = double.tryParse(_manualRateController.text.trim());
    if (amount == null || rate == null) return;

    final converted = convertAmount(amount, rate);
    setState(() {
      _status = _ConversionStatus.success;
      _result = converted;
      _rateUsed = rate;
    });
    recordCalculation(
      ref,
      type: 'currency_conversion',
      toolName: 'Currency Converter',
      summary:
          '${amount.toStringAsFixed(2)} ${_fromController.text.trim().toUpperCase()} '
          '→ ${converted.toStringAsFixed(2)} '
          '${_toController.text.trim().toUpperCase()} (manual rate)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');

    return CalculatorScaffold(
      title: 'Currency Converter',
      children: [
        CalculatorField(label: 'Amount', controller: _amountController),
        Row(
          children: [
            Expanded(
              child: CalculatorField(
                label: 'From (e.g. USD)',
                controller: _fromController,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CalculatorField(
                label: 'To (e.g. NGN)',
                controller: _toController,
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: _status == _ConversionStatus.loading ? null : _convert,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: _status == _ConversionStatus.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black87,
                        ),
                      )
                    : const Text(
                        'Convert',
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
        if (_status == _ConversionStatus.error) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            _errorMessage ?? "Couldn't convert. Please try again.",
            style: AppTypography.body.copyWith(color: AppColors.negative),
          ),
          const SizedBox(height: AppSpacing.md),
          CalculatorField(
            label: 'Enter exchange rate manually',
            controller: _manualRateController,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _convertManually,
              child: const Text('Convert with manual rate'),
            ),
          ),
        ],
        if (_status == _ConversionStatus.success && _result != null) ...[
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                CalculatorResultRow(
                  label: 'Converted amount',
                  value:
                      '${formatter.format(_result)} '
                      '${_toController.text.trim().toUpperCase()}',
                  emphasize: true,
                ),
                CalculatorResultRow(
                  label: 'Rate used',
                  value: formatter.format(_rateUsed),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
