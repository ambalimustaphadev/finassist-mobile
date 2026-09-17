import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../splash_colors.dart';
import '../splash_timeline.dart';

/// A visual animation-progress indicator, not a network loading spinner —
/// its fill tracks the splash's own timeline linearly, so it never jumps.
/// Paired with a short status caption, matching the reference.
class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final statusOpacity = SplashTimeline.statusIn.transform(clamped);

    return Opacity(
      opacity: statusOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 130,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
                  FractionallySizedBox(
                    widthFactor: clamped,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: kSplashCtaGradient,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'BUILDING A BRIGHTER TOMORROW',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
        ],
      ),
    );
  }
}
