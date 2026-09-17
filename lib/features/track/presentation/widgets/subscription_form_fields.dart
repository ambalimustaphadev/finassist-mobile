import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

InputDecoration _fieldDecoration(
  BuildContext context, {
  String? hintText,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.body(context).copyWith(
      color: context.colors.textMuted,
    ),
    errorText: errorText,
    filled: true,
    fillColor: context.colors.surface,
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
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;

  /// Defaults to [TextCapitalization.sentences]. Callers pass
  /// [TextCapitalization.words] for a name-like field or
  /// [TextCapitalization.none] for a machine-readable value (a website
  /// URL, an amount).
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium(context)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: AppTypography.body(
            context,
          ).copyWith(color: context.colors.textPrimary),
          decoration: _fieldDecoration(
            context,
            hintText: hintText,
            errorText: errorText,
          ),
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
        Text(label, style: AppTypography.bodyMedium(context)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: context.colors.surfaceElevated,
              style: AppTypography.body(
                context,
              ).copyWith(color: context.colors.textPrimary),
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
              primary: context.colors.accent,
              onPrimary: context.colors.textOnAccent,
              surface: context.colors.surface,
              onSurface: context.colors.textPrimary,
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
        Text(label, style: AppTypography.bodyMedium(context)),
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
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: errorText != null
                  ? Border.all(color: context.colors.negative)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: context.colors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  date == null
                      ? 'Select date'
                      : DateFormat('MMMM d, yyyy').format(date!),
                  style: AppTypography.body(context).copyWith(
                    color: date == null
                        ? context.colors.textMuted
                        : context.colors.textPrimary,
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
            style: AppTypography.caption(
              context,
            ).copyWith(color: context.colors.negative),
          ),
        ],
      ],
    );
  }
}
