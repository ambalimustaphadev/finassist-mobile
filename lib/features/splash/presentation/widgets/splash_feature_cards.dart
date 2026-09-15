import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../splash_timeline.dart';

class _CardSpec {
  const _CardSpec({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.alignment,
    required this.interval,
    required this.floatPhase,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Alignment alignment;
  final Interval interval;
  final double floatPhase;
}

/// The four floating "Track / Plan / Save / Achieve" cards arranged around
/// the logo cluster, each a real widget (not artwork) so it can animate
/// independently: a staggered entrance, then a gentle continuous float.
class SplashFeatureCards extends StatelessWidget {
  const SplashFeatureCards({super.key, required this.t, required this.size});

  final double t;

  /// Side length of the square cluster region the cards are positioned
  /// within, relative to the logo at its center.
  final double size;

  static final _cards = [
    _CardSpec(
      label: 'Track',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.accentSoft,
      alignment: const Alignment(-0.78, -0.86),
      interval: SplashTimeline.trackCard,
      floatPhase: 0.0,
    ),
    _CardSpec(
      label: 'Plan',
      icon: Icons.event_note_rounded,
      iconColor: const Color(0xFF6FB6F2),
      alignment: const Alignment(0.8, -0.62),
      interval: SplashTimeline.planCard,
      floatPhase: 0.45,
    ),
    _CardSpec(
      label: 'Save',
      icon: Icons.savings_rounded,
      iconColor: const Color(0xFFB79CF2),
      alignment: const Alignment(-0.98, 0.28),
      interval: SplashTimeline.saveCard,
      floatPhase: 0.8,
    ),
    _CardSpec(
      label: 'Achieve',
      icon: Icons.track_changes_rounded,
      iconColor: AppColors.accentStrong,
      alignment: const Alignment(0.94, 0.5),
      interval: SplashTimeline.achieveCard,
      floatPhase: 0.2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final cardSize = size * 0.3;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final card in _cards)
            Align(
              alignment: card.alignment,
              child: _FloatingCard(t: clamped, size: cardSize, spec: card),
            ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.t, required this.size, required this.spec});

  final double t;
  final double size;
  final _CardSpec spec;

  @override
  Widget build(BuildContext context) {
    // `easeOutBack` intentionally overshoots past 1.0 for its bounce, so
    // it drives scale/translate directly but is clamped for opacity, which
    // requires a value in [0, 1].
    final reveal = spec.interval.transform(t);
    if (reveal <= 0.001) return SizedBox.square(dimension: size);
    final revealOpacity = reveal.clamp(0.0, 1.0);

    // Gentle continuous float, ramped in only once the card has arrived so
    // it never fights the entrance motion.
    final floatEnvelope = revealOpacity >= 0.999 ? 1.0 : 0.0;
    final floatY =
        math.sin((t * 2 * math.pi * 0.9) + (spec.floatPhase * 2 * math.pi)) *
        4 *
        floatEnvelope;

    return Opacity(
      opacity: revealOpacity,
      child: Transform.translate(
        offset: Offset(0, ((1 - revealOpacity) * 22) + floatY),
        child: Transform.scale(
          scale: 0.82 + (0.18 * reveal),
          child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.symmetric(vertical: size * 0.1),
            decoration: BoxDecoration(
              color: AppColors.drawerBackground.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(spec.icon, color: spec.iconColor, size: size * 0.26),
                SizedBox(height: size * 0.06),
                Text(
                  spec.label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
