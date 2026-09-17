import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

// Fixed-dark, pre-auth brand composition — see onboarding_carousel_page.dart.
const _kOnboardingAccent = Color(0xFF35D39A);

/// The large circular mint "next" button used on onboarding pages 1–2 —
/// deliberately custom (not a default `FloatingActionButton`) so shadow,
/// radius and press feedback match the reference exactly.
class OnboardingArrowButton extends StatelessWidget {
  const OnboardingArrowButton({
    super.key,
    required this.onTap,
    this.semanticLabel = 'Next',
  });

  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: _kOnboardingAccent,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: _kOnboardingAccent.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF0E1A15),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// The labeled mint pill used for "Get Started" on the final onboarding
/// page — the last step calls for an explicit label, not a bare arrow,
/// since it's the one carousel action that leads somewhere materially
/// different (Register) rather than just paging forward.
class OnboardingGetStartedButton extends StatelessWidget {
  const OnboardingGetStartedButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: _kOnboardingAccent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: 6,
        shadowColor: _kOnboardingAccent.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.buttonLabel(context).copyWith(
                    color: const Color(0xFF0E1A15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Color(0xFF0E1A15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
