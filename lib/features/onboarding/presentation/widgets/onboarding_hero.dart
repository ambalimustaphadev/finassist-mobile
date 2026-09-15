import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// The tilted phone product shot for one onboarding page. The supplied
/// artwork already bakes in its own background/glow/pagination-dot
/// treatment — this widget shows it at its native 2:3 aspect ratio (never
/// cropped or distorted) and fades its bottom edge into
/// [AppColors.drawerBackground] so the artwork's own baked-in dots/CTA
/// pixels dissolve into the page rather than visually duplicating the real,
/// interactive footer built in Flutter just below it.
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.26,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.drawerBackground.withValues(alpha: 0),
                        AppColors.drawerBackground,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
