import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/recurring_payment.dart';

/// Embedded card listing detected recurring payments/subscriptions.
class RecurringPaymentsCard extends StatelessWidget {
  const RecurringPaymentsCard({super.key, required this.payments});

  final List<RecurringPayment> payments;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recurring payments', style: AppTypography.cardTitle),
          const Divider(color: AppColors.border, height: AppSpacing.lg),
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_repeat_rounded,
                    size: 18,
                    color: AppColors.categoryTransfers,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.name, style: AppTypography.bodyMedium),
                        const SizedBox(height: 2),
                        Text(payment.frequency, style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Text(
                    payment.amount.toNaira(),
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
