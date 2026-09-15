import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/subscription.dart';

/// A subtle, tinted status pill — never a loud/solid badge, per the
/// feature's restrained visual language.
class SubscriptionStatusBadge extends StatelessWidget {
  const SubscriptionStatusBadge({super.key, required this.status});

  final SubscriptionStatus status;

  Color get _color {
    switch (status) {
      case SubscriptionStatus.active:
        return AppColors.accentStrong;
      case SubscriptionStatus.paused:
        return const Color(0xFFB98900);
      case SubscriptionStatus.cancelled:
        return AppColors.negative;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
