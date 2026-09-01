import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/insight_visuals.dart';
import '../../../../shared/widgets/highlighted_text.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/financial_insight.dart';

/// A single row inside the AI insights card: icon badge + copy with key
/// figures/categories highlighted in the accent color.
class InsightRow extends StatelessWidget {
  const InsightRow({super.key, required this.insight});

  final FinancialInsight insight;

  @override
  Widget build(BuildContext context) {
    final visual = insightVisuals[insight.type]!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: visual.icon, color: visual.color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: HighlightedText(
              text: insight.message,
              highlights: insight.highlights,
              style: AppTypography.body.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
