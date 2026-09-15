import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/subscription.dart';
import 'subscription_primary_button.dart';

/// The combination of filter values chosen in [showSubscriptionFilterSheet]
/// — `null` in any field means "no restriction" for that dimension.
class SubscriptionFilters {
  const SubscriptionFilters({
    this.status,
    this.category,
    this.frequency,
    this.paymentMethod,
  });

  final SubscriptionStatus? status;
  final SubscriptionCategory? category;
  final SubscriptionFrequency? frequency;
  final PaymentMethod? paymentMethod;

  static const empty = SubscriptionFilters();

  SubscriptionFilters copyWith({
    SubscriptionStatus? status,
    bool clearStatus = false,
    SubscriptionCategory? category,
    SubscriptionFrequency? frequency,
    PaymentMethod? paymentMethod,
  }) {
    return SubscriptionFilters(
      status: clearStatus ? null : (status ?? this.status),
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  bool get isEmpty =>
      status == null &&
      category == null &&
      frequency == null &&
      paymentMethod == null;
}

/// Opens the filter bottom sheet pre-seeded with [initial], returns the
/// applied [SubscriptionFilters] or `null` if dismissed without applying.
Future<SubscriptionFilters?> showSubscriptionFilterSheet(
  BuildContext context, {
  required SubscriptionFilters initial,
}) {
  return showModalBottomSheet<SubscriptionFilters>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(initial: initial),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final SubscriptionFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SubscriptionStatus? _status = widget.initial.status;
  late SubscriptionCategory? _category = widget.initial.category;
  late SubscriptionFrequency? _frequency = widget.initial.frequency;
  late PaymentMethod? _paymentMethod = widget.initial.paymentMethod;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter subscriptions', style: AppTypography.sectionHeading),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Status', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusChip(
                  label: 'All',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                for (final status in SubscriptionStatus.values)
                  _StatusChip(
                    label: status.label,
                    selected: _status == status,
                    onTap: () => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DropdownRow<SubscriptionCategory>(
              label: 'Category',
              value: _category,
              placeholder: 'All categories',
              items: SubscriptionCategory.values,
              labelOf: (c) => c!.label,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownRow<SubscriptionFrequency>(
              label: 'Billing frequency',
              value: _frequency,
              placeholder: 'All frequencies',
              items: SubscriptionFrequency.values,
              labelOf: (f) => f!.label,
              onChanged: (v) => setState(() => _frequency = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownRow<PaymentMethod>(
              label: 'Payment method',
              value: _paymentMethod,
              placeholder: 'All payment methods',
              items: PaymentMethod.values,
              labelOf: (m) => m!.label,
              onChanged: (v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            SubscriptionPrimaryButton(
              label: 'Apply filters',
              onPressed: () => Navigator.of(context).pop(
                SubscriptionFilters(
                  status: _status,
                  category: _category,
                  frequency: _frequency,
                  paymentMethod: _paymentMethod,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _status = null;
                  _category = null;
                  _frequency = null;
                  _paymentMethod = null;
                }),
                child: Text(
                  'Clear all',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDeep : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DropdownRow<T extends Object> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final String placeholder;
  final List<T> items;
  final String Function(T?) labelOf;
  final ValueChanged<T?> onChanged;

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
            child: DropdownButton<T?>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceElevated,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              items: [
                DropdownMenuItem<T?>(value: null, child: Text(placeholder)),
                for (final item in items)
                  DropdownMenuItem<T?>(value: item, child: Text(labelOf(item))),
              ],
              onChanged: (v) => onChanged(v),
            ),
          ),
        ),
      ],
    );
  }
}
