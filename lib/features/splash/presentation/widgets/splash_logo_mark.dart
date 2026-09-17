import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/finassist_logo.dart';
import '../splash_colors.dart';
import '../splash_timeline.dart';

/// The FinAssist mark: the project's real `splash_logo.png` asset
/// (unaltered — never redrawn or recolored) scaling/fading into a soft
/// glowing backdrop, then settling into a very slight breathing pulse for
/// the rest of the sequence.
class SplashLogoMark extends StatelessWidget {
  const SplashLogoMark({super.key, required this.t, required this.size});

  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final reveal = SplashTimeline.logoReveal.transform(clamped);
    if (reveal <= 0.001) return SizedBox.square(dimension: size);

    // Breathing pulse only ramps in once the reveal has settled, and is
    // deliberately tiny (±1.6%) so it reads as "alive", not distracting.
    final breathe =
        reveal >= 0.999
            ? math.sin(clamped * 2 * math.pi * 1.6) * 0.016
            : 0.0;
    final scale = (0.72 + (0.28 * reveal)) + breathe;

    return Opacity(
      opacity: reveal,
      child: Transform.scale(
        scale: scale,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft glow backdrop, standing in for the reference's
              // rounded emerald tile without recoloring the asset itself.
              Container(
                width: size * 0.86,
                height: size * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSplashAccentStrong.withValues(
                        alpha: 0.45 * reveal,
                      ),
                      blurRadius: size * 0.5,
                      spreadRadius: size * 0.02,
                    ),
                  ],
                ),
              ),
              FinAssistLogo(size: size * 0.78),
            ],
          ),
        ),
      ),
    );
  }
}
