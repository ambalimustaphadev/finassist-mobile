import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../splash_colors.dart';
import '../splash_timeline.dart';

/// The FinAssist wordmark and tagline, real Flutter [Text] (never baked
/// into artwork) so it stays crisp, responsive and localizable.
class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final wordmarkOpacity = SplashTimeline.wordmark.transform(clamped);
    final taglineOpacity = SplashTimeline.tagline.transform(clamped);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: wordmarkOpacity,
          child: Transform.translate(
            offset: Offset(0, (1 - wordmarkOpacity) * 12),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Fin',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  TextSpan(
                    text: 'Assist',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: kSplashAccent,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: taglineOpacity,
          child: Transform.translate(
            offset: Offset(0, (1 - taglineOpacity) * 8),
            child: Text(
              'Smarter Finances.\nA Brighter You.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
