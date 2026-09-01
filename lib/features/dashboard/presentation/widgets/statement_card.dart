import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/models/bank_statement.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// Shows the currently uploaded bank statement that the AI assistant is
/// using as context. Tapping simulates opening/re-syncing the statement.
class StatementCard extends StatelessWidget {
  const StatementCard({super.key, required this.statement, this.onTap});

  final BankStatement statement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.description_rounded,
            color: AppColors.accentStrong,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statement', style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  statement.fileName,
                  style: AppTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateRange(statement.periodStart, statement.periodEnd),
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
