import 'package:flutter/material.dart';

import '../splash_colors.dart';
import '../splash_timeline.dart';

/// The persistent dark-emerald atmosphere behind every other splash layer:
/// a near-black backdrop with two soft radial glows (one behind the logo
/// cluster, one low behind the waves) rather than a baked-in background
/// image, so it stays crisp at any screen size and never has to be paired
/// against a mismatched photo.
class SplashBackgroundScene extends StatelessWidget {
  const SplashBackgroundScene({super.key, required this.t});

  final double t;

  /// Deeper than [kSplashDarkBg] at the edges for a more cinematic
  /// near-black — the mid-tone the glows blend into, keeping this in the
  /// same dark-emerald family as the rest of the app rather than
  /// introducing an unrelated black.
  static const _edgeShade = Color(0xFF050A08);

  @override
  Widget build(BuildContext context) {
    final opacity = SplashTimeline.backgroundFadeIn.transform(
      t.clamp(0.0, 1.0),
    );

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _edgeShade),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base vertical tone: slightly lighter emerald-black in the
            // middle, deepening toward the top and bottom edges.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_edgeShade, kSplashDarkBg, _edgeShade],
                ),
              ),
            ),
            // Ambient glow behind the logo/card cluster.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.28),
                  radius: 0.75,
                  colors: [
                    kSplashAccentStrong.withValues(alpha: 0.22),
                    kSplashAccentStrong.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Low ambient glow behind the wave ribbons.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.15, 0.95),
                  radius: 0.9,
                  colors: [
                    kSplashAccent.withValues(alpha: 0.16),
                    kSplashAccent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
