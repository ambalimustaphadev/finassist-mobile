import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// Top row shared by all onboarding carousel pages: the FinAssist wordmark
/// (reusing the same logo asset + "Fin"/"Assist" split-color pattern as the
/// rest of the app's branding) on the left, "Skip" on the right — matching
/// the reference's dark header exactly, with no tagline underneath.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/splash/splash_logo.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            style: AppTypography.sectionHeading.copyWith(fontSize: 18),
            children: [
              TextSpan(
                text: 'Fin',
                style: TextStyle(color: AppColors.drawerText),
              ),
              TextSpan(
                text: 'Assist',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Skip',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.drawerTextMuted,
            ),
          ),
        ),
      ],
    );
  }
}
