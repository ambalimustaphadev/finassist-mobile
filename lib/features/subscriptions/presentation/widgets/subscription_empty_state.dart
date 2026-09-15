import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import 'subscription_primary_button.dart';

/// The "No subscriptions yet" empty state — a large soft-green circular
/// icon badge, title, message, and a filled CTA. Deliberately more premium
/// than the generic `EmptyStateView` used elsewhere in the app, matching
/// the reference design's dedicated empty-state screen.
class SubscriptionEmptyState extends StatelessWidget {
  const SubscriptionEmptyState({
    super.key,
    this.title = 'No subscriptions yet',
    this.message =
        'Add your first subscription to keep track of your recurring '
        'payments in one place.',
    this.actionLabel = 'Add subscription',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.onboardingMintTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 44,
              color: AppColors.accentStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: SubscriptionPrimaryButton(
                label: actionLabel,
                onPressed: onAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
