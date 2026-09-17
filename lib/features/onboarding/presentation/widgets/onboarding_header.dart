import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/finassist_logo.dart';

// Fixed-dark, pre-auth brand composition — see onboarding_carousel_page.dart.
const _kOnboardingLightText = Color(0xFFF5F7F5);
const _kOnboardingMutedText = Color(0xFF8FA398);
const _kOnboardingAccent = Color(0xFF35D39A);

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
        const FinAssistLogo(size: 24),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            style: AppTypography.sectionHeading(
              context,
            ).copyWith(fontSize: 18),
            children: const [
              TextSpan(text: 'Fin', style: TextStyle(color: _kOnboardingLightText)),
              TextSpan(text: 'Assist', style: TextStyle(color: _kOnboardingAccent)),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Skip',
            style: AppTypography.bodyMedium(context).copyWith(
              color: _kOnboardingMutedText,
            ),
          ),
        ),
      ],
    );
  }
}
