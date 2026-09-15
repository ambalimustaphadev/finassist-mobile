import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/fade_slide_in.dart';
import 'onboarding_hero.dart';
import 'onboarding_indicator.dart';
import 'onboarding_header.dart';
import 'onboarding_nav_button.dart';

/// One page of the pre-login onboarding carousel — a dark, premium
/// composition shared by all 3 pages (header, eyebrow, headline,
/// description, product-shot hero, pagination + CTA, microcopy). Only the
/// content and the primary action's behavior differ per page; the layout
/// and visual language are identical, per the reference design.
class OnboardingCarouselPage extends StatelessWidget {
  const OnboardingCarouselPage({
    super.key,
    required this.asset,
    required this.eyebrow,
    required this.headline,
    required this.description,
    required this.microcopy,
    required this.pageIndex,
    required this.pageCount,
    required this.onSkip,
    required this.onPrimaryAction,
    this.primarySemanticLabel = 'Next',
    this.getStartedLabel,
  });

  final String asset;
  final String eyebrow;
  final String headline;
  final String description;
  final String microcopy;
  final int pageIndex;
  final int pageCount;
  final VoidCallback onSkip;
  final VoidCallback onPrimaryAction;
  final String primarySemanticLabel;

  /// When set (the final page), the CTA is a labeled pill ("Get Started")
  /// instead of the bare circular arrow every earlier page uses.
  final String? getStartedLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _CarouselBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                OnboardingHeader(onSkip: onSkip),
                const SizedBox(height: AppSpacing.xxl),
                FadeSlideIn(
                  key: ValueKey('onboarding-carousel-text-$pageIndex'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        headline,
                        style: AppTypography.greeting.copyWith(
                          fontSize: 27,
                          height: 1.22,
                          color: AppColors.drawerText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          description,
                          style: AppTypography.body.copyWith(
                            color: AppColors.drawerTextMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FadeSlideIn(
                    key: ValueKey('onboarding-carousel-hero-$pageIndex'),
                    child: OnboardingHero(asset: asset),
                  ),
                ),
                Row(
                  children: [
                    OnboardingIndicator(
                      pageCount: pageCount,
                      activeIndex: pageIndex,
                    ),
                    const Spacer(),
                    if (getStartedLabel != null)
                      OnboardingGetStartedButton(
                        label: getStartedLabel!,
                        onTap: onPrimaryAction,
                      )
                    else
                      OnboardingArrowButton(
                        onTap: onPrimaryAction,
                        semanticLabel: primarySemanticLabel,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  microcopy,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.drawerTextMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Near-black base with an extremely subtle emerald glow — deliberately
/// restrained so it complements the hero artwork (which already carries its
/// own baked-in glow/background) rather than competing with it.
class _CarouselBackground extends StatelessWidget {
  const _CarouselBackground();

  @override
  Widget build(BuildContext context) {
    // `RadialGradient` colors paint opaquely over whatever's beneath (there's
    // nothing beneath this bottommost layer), so a translucent accent color
    // here would blend against transparent, not against the dark
    // background — pre-mixing opaque colors is what actually reads as "dark
    // background lightening subtly toward mint," not a washed-out patch
    // with a hard edge.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.2,
          colors: [
            Color.lerp(AppColors.drawerBackground, AppColors.accent, 0.14)!,
            Color.lerp(AppColors.drawerBackground, AppColors.accent, 0.05)!,
            AppColors.drawerBackground,
          ],
          stops: const [0, 0.45, 0.85],
        ),
      ),
    );
  }
}
