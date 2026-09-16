import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../profile/data/models/preferences.dart';
import '../../data/models/subscription.dart';
import '../../domain/subscription_schedule.dart';
import 'subscription_icon.dart';

/// A row in the Overview's "Upcoming" list: icon, name, amount/frequency/
/// next date, and a right-aligned relative countdown chip.
class UpcomingRenewalTile extends StatelessWidget {
  const UpcomingRenewalTile({
    super.key,
    required this.subscription,
    required this.nextDate,
    required this.onTap,
  });

  final Subscription subscription;
  final DateTime nextDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final symbol = currencyOptionFor(subscription.currency).symbol;
    final countdown = relativeCountdown(nextDate);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              SubscriptionIcon(
                name: subscription.name,
                category: subscription.category,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subscription.name, style: AppTypography.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${formatCurrency(subscription.amount, symbol)} · '
                      '${subscription.frequency.label} · '
                      '${DateFormat('MMM d, yyyy').format(nextDate)}',
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  countdown,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
