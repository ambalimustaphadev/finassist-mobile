import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../profile/data/models/preferences.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../data/models/subscription.dart';
import '../../domain/subscription_schedule.dart';
import '../../domain/subscription_totals.dart';
import '../providers/subscription_controller.dart';
import '../widgets/subscription_empty_state.dart';
import '../widgets/upcoming_renewal_tile.dart';
import 'add_subscription_flow_screen.dart';
import 'all_subscriptions_screen.dart';
import 'subscription_detail_screen.dart';

/// The Subscription Tracker's entry screen, reached only from Tools' new
/// "Track" section — header, monthly/yearly spend summary and the most
/// relevant upcoming renewals.
class SubscriptionOverviewScreen extends ConsumerWidget {
  const SubscriptionOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsControllerProvider);
    final currency = ref.watch(preferencesControllerProvider).currency;
    final symbol = currencyOptionFor(currency).symbol;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textPrimary,
                  ),
                  const Spacer(),
                  _AddButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddSubscriptionFlowScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () =>
                    ref.read(subscriptionsControllerProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    Text('Subscriptions', style: AppTypography.greeting),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Keep track of your recurring payments and upcoming '
                      'renewals.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (state.status == SubscriptionsLoadStatus.loading)
                      const LoadingStateView(height: 300)
                    else if (state.status == SubscriptionsLoadStatus.error)
                      ErrorStateView(
                        message: state.loadError ??
                            'Something went wrong. Please try again.',
                        onRetry: () => ref
                            .read(subscriptionsControllerProvider.notifier)
                            .refresh(),
                      )
                    else if (state.subscriptions.isEmpty)
                      SubscriptionEmptyState(
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddSubscriptionFlowScreen(),
                          ),
                        ),
                      )
                    else
                      _OverviewContent(
                        subscriptions: state.subscriptions,
                        symbol: symbol,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.subscriptions, required this.symbol});

  final List<Subscription> subscriptions;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final monthly = totalMonthlySpend(subscriptions);
    final yearly = totalYearlySpend(subscriptions);
    final count = subscriptions.length;
    final countLabel = 'Across $count subscription${count == 1 ? '' : 's'}';

    final upcoming = subscriptions
        .where((s) => s.status == SubscriptionStatus.active)
        .map((s) => (s, nextOccurrence(s.nextBillingDate, s.frequency)))
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final topUpcoming = upcoming.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Monthly spend',
                value: formatCurrency(monthly, symbol),
                subtitle: countLabel,
                background: AppColors.onboardingMintTint,
                valueColor: AppColors.accentStrong,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SummaryCard(
                label: 'Yearly spend',
                value: formatCurrency(yearly, symbol),
                subtitle: "That's ${formatCurrency(monthly, symbol)}/month",
                background: AppColors.categoryBills.withValues(alpha: 0.12),
                valueColor: AppColors.categoryBills,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _SelectorPill(
              label: 'Upcoming (${topUpcoming.length})',
              selected: true,
              onTap: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            _SelectorPill(
              label: 'All subscriptions (${subscriptions.length})',
              selected: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AllSubscriptionsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (topUpcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'No upcoming renewals for active subscriptions.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          )
        else ...[
          for (final entry in topUpcoming) ...[
            UpcomingRenewalTile(
              subscription: entry.$1,
              nextDate: entry.$2,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionDetailScreen(
                    subscriptionId: entry.$1.id,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AllSubscriptionsScreen(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                'View all upcoming',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.background,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color background;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.financialNumberMedium.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SelectorPill extends StatelessWidget {
  const _SelectorPill({
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
          color: selected ? AppColors.accentDeep : AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentDeep,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
