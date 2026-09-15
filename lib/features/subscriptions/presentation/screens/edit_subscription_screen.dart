import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/models/preferences.dart';
import '../../data/models/subscription.dart';
import '../providers/subscription_controller.dart';
import '../widgets/subscription_form_fields.dart';
import '../widgets/subscription_primary_button.dart';

/// Reuses the same field widgets as the Add flow, pre-filled from
/// [subscription]. Only fields that actually changed are sent in the PATCH
/// body — untouched fields are never accidentally overwritten with null,
/// but a field the user deliberately clears (e.g. removing the website) is
/// sent as `null` since that's a real, intentional change.
class EditSubscriptionScreen extends ConsumerStatefulWidget {
  const EditSubscriptionScreen({super.key, required this.subscription});

  final Subscription subscription;

  @override
  ConsumerState<EditSubscriptionScreen> createState() => _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState extends ConsumerState<EditSubscriptionScreen> {
  late final _nameController = TextEditingController(text: widget.subscription.name);
  late final _amountController = TextEditingController(
    text: _formatAmount(widget.subscription.amount),
  );
  late final _websiteController = TextEditingController(
    text: widget.subscription.website ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.subscription.notes ?? '',
  );

  late String _currency = widget.subscription.currency;
  late SubscriptionFrequency _frequency = widget.subscription.frequency;
  late DateTime? _nextBillingDate = widget.subscription.nextBillingDate;
  late SubscriptionCategory? _category = widget.subscription.category;
  late PaymentMethod? _paymentMethod = widget.subscription.paymentMethod;

  String? _nameError;
  String? _amountError;
  String? _dateError;
  bool _isSaving = false;
  String? _saveError;

  static String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildChanges() {
    final original = widget.subscription;
    final changes = <String, dynamic>{};

    final name = _nameController.text.trim();
    if (name != original.name) changes['name'] = name;

    final amount = double.parse(_amountController.text.trim());
    if (amount != original.amount) changes['amount'] = amount;

    if (_currency != original.currency) changes['currency'] = _currency;
    if (_frequency != original.frequency) changes['frequency'] = _frequency.apiValue;

    if (_nextBillingDate != original.nextBillingDate) {
      changes['next_billing_date'] =
          DateFormat('yyyy-MM-dd').format(_nextBillingDate!);
    }

    if (_category != original.category) {
      changes['category'] = _category?.apiValue;
    }
    if (_paymentMethod != original.paymentMethod) {
      changes['payment_method'] = _paymentMethod?.apiValue;
    }

    final website = _websiteController.text.trim();
    if (website != (original.website ?? '')) {
      changes['website'] = website.isEmpty ? null : website;
    }

    final notes = _notesController.text.trim();
    if (notes != (original.notes ?? '')) {
      changes['notes'] = notes.isEmpty ? null : notes;
    }

    return changes;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Enter a subscription name.' : null;
      _amountError = (amount == null || amount <= 0) ? 'Enter a valid amount.' : null;
      _dateError = _nextBillingDate == null ? 'Select the next billing date.' : null;
    });
    if (_nameError != null || _amountError != null || _dateError != null) return;

    final changes = _buildChanges();
    if (changes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await ref
          .read(subscriptionsControllerProvider.notifier)
          .update(widget.subscription.id, changes);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Edit subscription', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SubscriptionTextField(
              label: 'Name',
              controller: _nameController,
              errorText: _nameError,
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionTextField(
              label: 'Amount',
              controller: _amountController,
              errorText: _amountError,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionDropdownField<CurrencyOption>(
              label: 'Currency',
              value: currencyOptionFor(_currency),
              items: supportedCurrencies,
              labelOf: (c) => '${c.code} · ${c.symbol} ${c.label}',
              onChanged: (c) => setState(() => _currency = c.code),
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionDropdownField<SubscriptionFrequency>(
              label: 'Billing frequency',
              value: _frequency,
              items: SubscriptionFrequency.values,
              labelOf: (f) => f.label,
              onChanged: (f) => setState(() => _frequency = f),
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionDateField(
              label: 'Next billing date',
              date: _nextBillingDate,
              errorText: _dateError,
              onChanged: (d) => setState(() => _nextBillingDate = d),
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionDropdownField<SubscriptionCategory?>(
              label: 'Category',
              value: _category,
              items: [null, ...SubscriptionCategory.values],
              labelOf: (c) => c?.label ?? 'None',
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionDropdownField<PaymentMethod?>(
              label: 'Payment method',
              value: _paymentMethod,
              items: [null, ...PaymentMethod.values],
              labelOf: (m) => m?.label ?? 'None',
              onChanged: (m) => setState(() => _paymentMethod = m),
            ),
            const SizedBox(height: AppSpacing.md),
            SubscriptionTextField(label: 'Website', controller: _websiteController),
            const SizedBox(height: AppSpacing.md),
            SubscriptionTextField(
              label: 'Notes',
              controller: _notesController,
              maxLines: 3,
            ),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _saveError!,
                style: AppTypography.body.copyWith(color: AppColors.negative),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SubscriptionPrimaryButton(
              label: 'Save changes',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
