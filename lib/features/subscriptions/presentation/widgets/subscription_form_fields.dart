import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

InputDecoration _fieldDecoration({String? hintText, String? errorText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
    errorText: errorText,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  );
}

/// A labeled text input, shared by the Add and Edit subscription forms.
class SubscriptionTextField extends StatelessWidget {
  const SubscriptionTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: _fieldDecoration(hintText: hintText, errorText: errorText),
        ),
      ],
    );
  }
}

/// A labeled dropdown, shared by the Add and Edit subscription forms.
class SubscriptionDropdownField<T> extends StatelessWidget {
  const SubscriptionDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              items: [
                for (final item in items)
                  DropdownMenuItem(value: item, child: Text(labelOf(item))),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A labeled date field that opens a themed [showDatePicker] on tap.
class SubscriptionDateField extends StatelessWidget {
  const SubscriptionDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accentDeep,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: errorText != null
                  ? Border.all(color: AppColors.negative)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  date == null
                      ? 'Select date'
                      : DateFormat('MMMM d, yyyy').format(date!),
                  style: AppTypography.body.copyWith(
                    color: date == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.negative),
          ),
        ],
      ],
    );
  }
}
