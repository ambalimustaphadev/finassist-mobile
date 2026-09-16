import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Shared shell for every Tools calculator screen: a titled app bar and a
/// scrollable, consistently-padded body — so each calculator only needs to
/// supply its own inputs and result, not its own layout boilerplate.
class CalculatorScaffold extends StatelessWidget {
  const CalculatorScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(title, style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: children,
        ),
      ),
    );
  }
}

/// A labeled numeric input — every calculator's inputs are numbers
/// (amounts, rates, terms), so this is the one input widget the whole
/// feature needs.
class CalculatorField extends StatelessWidget {
  const CalculatorField({
    super.key,
    required this.label,
    required this.controller,
    this.suffixText,
  });

  final String label;
  final TextEditingController controller;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textCapitalization: TextCapitalization.none,
            style: AppTypography.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              suffixText: suffixText,
              suffixStyle: AppTypography.body,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled result line inside a calculator's result card.
class CalculatorResultRow extends StatelessWidget {
  const CalculatorResultRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body),
          Text(
            value,
            style: emphasize
                ? AppTypography.financialNumberMedium
                : AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
