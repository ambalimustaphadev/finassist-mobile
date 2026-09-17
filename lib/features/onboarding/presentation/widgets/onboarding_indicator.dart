import 'package:flutter/material.dart';

// Fixed-dark, pre-auth brand composition — see onboarding_carousel_page.dart.
const _kOnboardingMutedText = Color(0xFF8FA398);
const _kOnboardingAccent = Color(0xFF35D39A);

/// Pagination dots for the onboarding carousel — fixed-size circles that
/// only change color (never width) when active, matching the reference
/// exactly (unlike the widening-pill style used elsewhere in the app).
class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.pageCount,
    required this.activeIndex,
  });

  final int pageCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pageCount; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == activeIndex
                  ? _kOnboardingAccent
                  : _kOnboardingMutedText.withValues(alpha: 0.35),
            ),
          ),
        ],
      ],
    );
  }
}
