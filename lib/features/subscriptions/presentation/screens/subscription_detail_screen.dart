import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/confirm_action_dialog.dart';
import '../../../profile/data/models/preferences.dart';
import '../../data/models/subscription.dart';
import '../../domain/subscription_schedule.dart';
import '../providers/subscription_controller.dart';
import '../widgets/subscription_action_menu_sheet.dart';
import '../widgets/subscription_icon.dart';
import '../widgets/subscription_status_badge.dart';
import 'edit_subscription_screen.dart';

class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  final int subscriptionId;

  Subscription? _find(List<Subscription> subscriptions) {
    for (final s in subscriptions) {
      if (s.id == subscriptionId) return s;
    }
    return null;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(message, style: const TextStyle(color: AppColors.textPrimary)),
        ),
      );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final action = await showSubscriptionActionMenu(context, subscription: subscription);
    if (action == null || !context.mounted) return;

    final notifier = ref.read(subscriptionsControllerProvider.notifier);

    if (action == SubscriptionAction.edit) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EditSubscriptionScreen(subscription: subscription)),
      );
      return;
    }

    if (action == SubscriptionAction.pause) {
      try {
        await notifier.update(subscription.id, {'status': 'paused'});
        if (context.mounted) _showSnack(context, 'Subscription paused.');
      } on ApiException catch (e) {
        if (context.mounted) _showSnack(context, e.message);
      }
      return;
    }

    if (action == SubscriptionAction.cancel) {
      try {
        await notifier.update(subscription.id, {'status': 'cancelled'});
        if (context.mounted) _showSnack(context, 'Subscription cancelled.');
      } on ApiException catch (e) {
        if (context.mounted) _showSnack(context, e.message);
      }
      return;
    }

    // action == SubscriptionAction.delete
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Delete subscription?',
      message:
          'This will permanently delete "${subscription.name}". This '
          'action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await notifier.delete(subscription.id);
      if (context.mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (context.mounted) _showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsControllerProvider);
    final subscription = _find(state.subscriptions);

    if (subscription == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const Center(child: Text('This subscription is no longer available.')),
      );
    }

    final symbol = currencyOptionFor(subscription.currency).symbol;
    final nextDate = nextOccurrence(subscription.nextBillingDate, subscription.frequency);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Subscription', style: AppTypography.screenTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditSubscriptionScreen(subscription: subscription),
              ),
            ),
            child: Text(
              'Edit',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.accentDeep),
            ),
          ),
          IconButton(
            onPressed: () => _handleAction(context, ref, subscription),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                SubscriptionIcon(
                  name: subscription.name,
                  category: subscription.category,
                  size: 56,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.name, style: AppTypography.sectionHeading),
                      const SizedBox(height: AppSpacing.xs),
                      SubscriptionStatusBadge(status: subscription.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Column(
                children: [
                  Text(
                    formatCurrency(subscription.amount, symbol),
                    style: AppTypography.financialNumberLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'per ${subscription.frequency.shortUnit}',
                    style: AppTypography.body.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.event_repeat_rounded,
                    label: 'Next payment',
                    value: DateFormat('MMMM d, yyyy').format(nextDate),
                    trailing: relativeCountdown(nextDate),
                  ),
                  if (subscription.category != null)
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: subscription.category!.label,
                    ),
                  if (subscription.paymentMethod != null)
                    _DetailRow(
                      icon: Icons.credit_card_rounded,
                      label: 'Payment method',
                      value: subscription.paymentMethod!.label,
                    ),
                  if (subscription.website != null && subscription.website!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.link_rounded,
                      label: 'Website',
                      value: subscription.website!,
                      valueColor: AppColors.accentDeep,
                      onTap: () => _openWebsite(subscription.website!),
                    ),
                  if (subscription.notes != null && subscription.notes!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: subscription.notes!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null) await launchUrl(uri);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? trailing;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.body),
            const Spacer(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(color: valueColor),
                    textAlign: TextAlign.right,
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
