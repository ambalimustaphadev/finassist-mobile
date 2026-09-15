import 'package:flutter/animation.dart';

/// Single source of truth for the splash's stage timing. Every layer reads
/// its sub-animation from the same master [AnimationController] via these
/// intervals so all stages overlap and blend into one continuous ~2.7s
/// sequence instead of feeling like a slideshow.
///
/// Stage windows (of [totalDuration]):
/// Background ambience    0    → 400ms
/// Logo reveal             250  → 800ms
/// Feature cards           500  → 1100ms (staggered)
/// Orbit + particle        700  → 1300ms
/// Wordmark + tagline      900  → 1500ms
/// Waves + gentle motion   600  → 2600ms (continuous)
abstract final class SplashTimeline {
  static const totalDuration = Duration(milliseconds: 2600);

  /// Held at 100% progress before navigating away — see [SplashScreen].
  static const completionHold = Duration(milliseconds: 150);

  static const _totalMs = 2600.0;

  static Interval _interval(
    double startMs,
    double endMs, {
    Curve curve = Curves.easeOut,
  }) {
    return Interval(startMs / _totalMs, endMs / _totalMs, curve: curve);
  }

  // Background ambience — the dark emerald glow settling in.
  static final backgroundFadeIn = _interval(0, 450);

  // Logo — scale/fade into place, then a very slight breathing pulse for
  // the remainder of the sequence (see SplashLogoMark).
  static final logoReveal = _interval(250, 800, curve: Curves.easeOutCubic);

  // Feature cards — staggered entrance, one Interval per card so each
  // starts a beat after the last.
  static final trackCard = _interval(500, 900, curve: Curves.easeOutBack);
  static final planCard = _interval(600, 1000, curve: Curves.easeOutBack);
  static final saveCard = _interval(680, 1080, curve: Curves.easeOutBack);
  static final achieveCard = _interval(760, 1160, curve: Curves.easeOutBack);

  // Orbit — the ring draws itself in, then its particle keeps gliding.
  static final orbitDraw = _interval(700, 1200, curve: Curves.easeOut);
  static final orbitParticle = _interval(750, 2600, curve: Curves.linear);

  // Brand — wordmark then tagline, a short beat apart.
  static final wordmark = _interval(900, 1400, curve: Curves.easeOutCubic);
  static final tagline = _interval(1050, 1500, curve: Curves.easeOutCubic);

  // Waves + bottom status — fade in early, then flow for the rest of the
  // sequence.
  static final wavesIn = _interval(600, 1300);
  static final statusIn = _interval(500, 950);
}
