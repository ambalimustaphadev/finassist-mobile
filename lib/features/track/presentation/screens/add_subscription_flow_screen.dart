import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../data/models/subscription.dart';
import '../providers/subscription_controller.dart';
import '../widgets/subscription_form_fields.dart';
import '../widgets/subscription_icon.dart';
import '../widgets/subscription_primary_button.dart';
import '../widgets/subscription_status_badge.dart';
import 'subscription_detail_screen.dart';

enum _Stage { basicInfo, details, review, success }

/// A single pushed screen driving the whole Add-subscription wizard as
/// internal stages (Basic info → Details → Review → Success), rather than
/// separate routes — this app has no router with named sub-routes, and a
/// stage enum keeps "Add another" a simple state reset instead of a fresh
/// navigation stack.
class AddSubscriptionFlowScreen extends ConsumerStatefulWidget {
  const AddSubscriptionFlowScreen({super.key});

  @override
  ConsumerState<AddSubscriptionFlowScreen> createState() =>
      _AddSubscriptionFlowScreenState();
}

class _AddSubscriptionFlowScreenState
    extends ConsumerState<AddSubscriptionFlowScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  _Stage _stage = _Stage.basicInfo;
  late String _currency;
  SubscriptionFrequency _frequency = SubscriptionFrequency.monthly;
  DateTime? _nextBillingDate;
  SubscriptionCategory? _category;
  PaymentMethod? _paymentMethod;

  String? _nameError;
  String? _amountError;
  String? _dateError;
  bool _isSaving = false;
  String? _saveError;
  Subscription? _created;

  @override
  void initState() {
    super.initState();
    _currency = ref.read(preferencesControllerProvider).currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _amountController.clear();
    _websiteController.clear();
    _notesController.clear();
    setState(() {
      _stage = _Stage.basicInfo;
      _frequency = SubscriptionFrequency.monthly;
      _nextBillingDate = null;
      _category = null;
      _paymentMethod = null;
      _nameError = null;
      _amountError = null;
      _dateError = null;
      _saveError = null;
      _created = null;
    });
  }

  void _handleBack() {
    if (_stage == _Stage.basicInfo) {
      Navigator.of(context).pop();
    } else if (_stage == _Stage.details) {
      setState(() => _stage = _Stage.basicInfo);
    } else if (_stage == _Stage.review) {
      setState(() => _stage = _Stage.details);
    }
  }

  void _continueFromBasicInfo() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Enter a subscription name.' : null;
      _amountError = (amount == null || amount <= 0)
          ? 'Enter a valid amount.'
          : null;
      _dateError = _nextBillingDate == null ? 'Select the next billing date.' : null;
    });
    if (_nameError != null || _amountError != null || _dateError != null) return;
    setState(() => _stage = _Stage.details);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final body = <String, dynamic>{
      'name': _nameController.text.trim(),
      'amount': double.parse(_amountController.text.trim()),
      'currency': _currency,
      'frequency': _frequency.apiValue,
      'next_billing_date': DateFormat('yyyy-MM-dd').format(_nextBillingDate!),
      if (_category != null) 'category': _category!.apiValue,
      if (_paymentMethod != null) 'payment_method': _paymentMethod!.apiValue,
      if (_websiteController.text.trim().isNotEmpty)
        'website': _websiteController.text.trim(),
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
    };

    try {
      final created =
          await ref.read(subscriptionsControllerProvider.notifier).create(body);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _created = created;
        _stage = _Stage.success;
      });
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
    if (_stage == _Stage.success) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _SuccessView(
          subscription: _created!,
          onViewSubscription: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SubscriptionDetailScreen(
                subscriptionId: _created!.id,
              ),
            ),
          ),
          onAddAnother: _resetForm,
        )),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _stage == _Stage.review ? 'Review subscription' : 'Add subscription',
          style: AppTypography.screenTitle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _StepHeader(stage: _stage),
            const SizedBox(height: AppSpacing.xl),
            switch (_stage) {
              _Stage.basicInfo => _BasicInfoStep(
                nameController: _nameController,
                amountController: _amountController,
                nameError: _nameError,
                amountError: _amountError,
                dateError: _dateError,
                currency: _currency,
                onCurrencyChanged: (v) => setState(() => _currency = v),
                frequency: _frequency,
                onFrequencyChanged: (v) => setState(() => _frequency = v),
                nextBillingDate: _nextBillingDate,
                onDateChanged: (v) => setState(() => _nextBillingDate = v),
                onContinue: _continueFromBasicInfo,
              ),
              _Stage.details => _DetailsStep(
                category: _category,
                onCategoryChanged: (v) => setState(() => _category = v),
                paymentMethod: _paymentMethod,
                onPaymentMethodChanged: (v) => setState(() => _paymentMethod = v),
                websiteController: _websiteController,
                notesController: _notesController,
                onContinue: () => setState(() => _stage = _Stage.review),
              ),
              _Stage.review => _ReviewStep(
                name: _nameController.text.trim(),
                amount: double.tryParse(_amountController.text.trim()) ?? 0,
                currency: _currency,
                frequency: _frequency,
                nextBillingDate: _nextBillingDate!,
                category: _category,
                paymentMethod: _paymentMethod,
                website: _websiteController.text.trim(),
                notes: _notesController.text.trim(),
                isSaving: _isSaving,
                saveError: _saveError,
                onSave: _save,
              ),
              _Stage.success => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.stage});

  final _Stage stage;

  static const _labels = ['Basic info', 'Details', 'Review'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = switch (stage) {
      _Stage.basicInfo => 0,
      _Stage.details => 1,
      _Stage.review => 2,
      _Stage.success => 3,
    };

    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIndex
                    ? AppColors.accentDeep
                    : AppColors.border,
              ),
            ),
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= currentIndex
                      ? AppColors.accentDeep
                      : AppColors.surfaceHighlight,
                ),
                alignment: Alignment.center,
                child: i < currentIndex
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: AppTypography.caption.copyWith(
                          color: i == currentIndex
                              ? Colors.white
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: AppTypography.caption.copyWith(
                  color: i <= currentIndex
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({
    required this.nameController,
    required this.amountController,
    required this.nameError,
    required this.amountError,
    required this.dateError,
    required this.currency,
    required this.onCurrencyChanged,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.nextBillingDate,
    required this.onDateChanged,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final TextEditingController amountController;
  final String? nameError;
  final String? amountError;
  final String? dateError;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final SubscriptionFrequency frequency;
  final ValueChanged<SubscriptionFrequency> onFrequencyChanged;
  final DateTime? nextBillingDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubscriptionTextField(
          label: 'What subscription is this?',
          controller: nameController,
          hintText: 'e.g. Netflix',
          errorText: nameError,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionTextField(
          label: 'How much do you pay?',
          controller: amountController,
          hintText: '0.00',
          errorText: amountError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionDropdownField<CurrencyOption>(
          label: 'Currency',
          value: currencyOptionFor(currency),
          items: supportedCurrencies,
          labelOf: (c) => '${c.code} · ${c.symbol} ${c.label}',
          onChanged: (c) => onCurrencyChanged(c.code),
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionDropdownField<SubscriptionFrequency>(
          label: 'Billing frequency',
          value: frequency,
          items: SubscriptionFrequency.values,
          labelOf: (f) => f.label,
          onChanged: onFrequencyChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionDateField(
          label: 'Next payment date',
          date: nextBillingDate,
          errorText: dateError,
          onChanged: onDateChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        SubscriptionPrimaryButton(label: 'Continue', onPressed: onContinue),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.category,
    required this.onCategoryChanged,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.websiteController,
    required this.notesController,
    required this.onContinue,
  });

  final SubscriptionCategory? category;
  final ValueChanged<SubscriptionCategory?> onCategoryChanged;
  final PaymentMethod? paymentMethod;
  final ValueChanged<PaymentMethod?> onPaymentMethodChanged;
  final TextEditingController websiteController;
  final TextEditingController notesController;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional details (optional)', style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        SubscriptionDropdownField<SubscriptionCategory?>(
          label: 'Category',
          value: category,
          items: [null, ...SubscriptionCategory.values],
          labelOf: (c) => c?.label ?? 'None',
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionDropdownField<PaymentMethod?>(
          label: 'Payment method',
          value: paymentMethod,
          items: [null, ...PaymentMethod.values],
          labelOf: (m) => m?.label ?? 'None',
          onChanged: onPaymentMethodChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionTextField(
          label: 'Website',
          controller: websiteController,
          hintText: 'https://...',
          keyboardType: TextInputType.url,
          textCapitalization: TextCapitalization.none,
        ),
        const SizedBox(height: AppSpacing.md),
        SubscriptionTextField(
          label: 'Notes',
          controller: notesController,
          hintText: 'Add any notes...',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.xl),
        SubscriptionPrimaryButton(label: 'Continue', onPressed: onContinue),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.name,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.nextBillingDate,
    required this.category,
    required this.paymentMethod,
    required this.website,
    required this.notes,
    required this.isSaving,
    required this.saveError,
    required this.onSave,
  });

  final String name;
  final double amount;
  final String currency;
  final SubscriptionFrequency frequency;
  final DateTime nextBillingDate;
  final SubscriptionCategory? category;
  final PaymentMethod? paymentMethod;
  final String website;
  final String notes;
  final bool isSaving;
  final String? saveError;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final symbol = currencyOptionFor(currency).symbol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SubscriptionIcon(name: name, category: category, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(name, style: AppTypography.sectionHeading),
                  ),
                  const SubscriptionStatusBadge(status: SubscriptionStatus.active),
                ],
              ),
              const Divider(height: AppSpacing.xxl, color: AppColors.border),
              _ReviewRow(label: 'Amount', value: formatCurrency(amount, symbol)),
              _ReviewRow(label: 'Frequency', value: frequency.label),
              _ReviewRow(
                label: 'Next payment',
                value: DateFormat('MMMM d, yyyy').format(nextBillingDate),
              ),
              if (category != null)
                _ReviewRow(label: 'Category', value: category!.label),
              if (paymentMethod != null)
                _ReviewRow(label: 'Payment method', value: paymentMethod!.label),
              if (website.isNotEmpty) _ReviewRow(label: 'Website', value: website),
              if (notes.isNotEmpty) _ReviewRow(label: 'Notes', value: notes),
            ],
          ),
        ),
        if (saveError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            saveError!,
            style: AppTypography.body.copyWith(color: AppColors.negative),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SubscriptionPrimaryButton(
          label: 'Save subscription',
          isLoading: isSaving,
          onPressed: onSave,
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.subscription,
    required this.onViewSubscription,
    required this.onAddAnother,
  });

  final Subscription subscription;
  final VoidCallback onViewSubscription;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.onboardingMintTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: AppColors.accentStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Subscription added', style: AppTypography.greeting),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${subscription.name} has been added to your subscriptions.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SubscriptionPrimaryButton(
            label: 'View subscription',
            onPressed: onViewSubscription,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onAddAnother,
              child: Text(
                'Add another',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
