import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The 6 stages this progress bar/"N of 6" label counts against — every
/// personalization page, including the introduction and completion.
const personalizationStepCount = 6;

/// The header row shared by all 6 personalization pages: an optional back
/// arrow, a thin animated green progress bar, an optional Skip, and a
/// "N of 6" label beneath — kept as one widget (not duplicated per screen)
/// so [PersonalizationScaffold] and the bespoke completion page can never
/// drift apart visually.
class PersonalizationHeader extends StatelessWidget {
  const PersonalizationHeader({
    super.key,
    required this.step,
    this.onBack,
    this.onSkip,
  });

  /// 1-based, e.g. `1` for "1 of 6".
  final int step;

  /// Null hides the back arrow (Page 1 — nothing before it).
  final VoidCallback? onBack;

  /// Null hides Skip (the completion page — nothing left to skip).
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: onBack == null
                    ? null
                    : Semantics(
                        button: true,
                        label: 'Back',
                        child: InkWell(
                          key: Key('personalization-back-$step'),
                          onTap: onBack,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.onboardingHeading,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: step / personalizationStepCount,
                    ),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: AppColors.authInputBorder,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: onSkip == null
                    ? null
                    : TextButton(
                        // `PageView`'s cache extent keeps the adjacent
                        // not-yet-visible screen built too, so a plain
                        // `find.text('Skip')` in a test can match more
                        // than one at once — a step-scoped key
                        // disambiguates.
                        key: Key('personalization-skip-$step'),
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'Skip',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onboardingBodyMuted,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$step of $personalizationStepCount',
            style: AppTypography.caption.copyWith(
              color: AppColors.onboardingBodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}
