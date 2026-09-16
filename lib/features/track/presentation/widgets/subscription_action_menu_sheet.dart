import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/subscription.dart';

enum SubscriptionAction { edit, pause, cancel, delete }

/// Opens the subscription detail's "..." action menu — rows are shown
/// conditionally based on the subscription's current [status] (no "Pause"
/// on an already-paused subscription, no "Cancel" on a cancelled one).
Future<SubscriptionAction?> showSubscriptionActionMenu(
  BuildContext context, {
  required Subscription subscription,
}) {
  return showModalBottomSheet<SubscriptionAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _ActionMenuSheet(subscription: subscription),
  );
}

class _ActionMenuSheet extends StatelessWidget {
  const _ActionMenuSheet({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final canPause = subscription.status != SubscriptionStatus.paused;
    final canCancel = subscription.status != SubscriptionStatus.cancelled;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(subscription.name, style: AppTypography.sectionHeading),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ActionRow(
              icon: Icons.edit_outlined,
              label: 'Edit subscription',
              onTap: () =>
                  Navigator.of(context).pop(SubscriptionAction.edit),
            ),
            if (canPause)
              _ActionRow(
                icon: Icons.pause_circle_outline_rounded,
                label: 'Pause subscription',
                onTap: () =>
                    Navigator.of(context).pop(SubscriptionAction.pause),
              ),
            if (canCancel)
              _ActionRow(
                icon: Icons.cancel_outlined,
                label: 'Cancel subscription',
                onTap: () =>
                    Navigator.of(context).pop(SubscriptionAction.cancel),
              ),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete subscription',
              color: AppColors.negative,
              onTap: () =>
                  Navigator.of(context).pop(SubscriptionAction.delete),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: resolvedColor, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: resolvedColor),
            ),
          ],
        ),
      ),
    );
  }
}
