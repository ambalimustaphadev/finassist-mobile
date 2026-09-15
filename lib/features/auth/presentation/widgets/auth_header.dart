import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The heading block shared by every auth screen: a large, bold navy title
/// plus a muted supporting line — the light-surface, no-dark-hero treatment
/// used across Login/Register, styled consistently with onboarding's own
/// heading/body color pair rather than a separate palette.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.greeting.copyWith(
            fontSize: 30,
            color: AppColors.onboardingHeading,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTypography.body.copyWith(
            color: AppColors.onboardingBodyMuted,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
