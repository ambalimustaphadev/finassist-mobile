import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../splash_colors.dart';
import '../splash_timeline.dart';

/// Slow, flowing green/teal wave ribbons near the bottom of the screen,
/// drawn with smooth Bezier curves rather than a wave PNG so they can
/// animate independently and stay crisp at any size.
class SplashWaves extends StatelessWidget {
  const SplashWaves({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final opacity = SplashTimeline.wavesIn.transform(clamped);
    if (opacity <= 0.001) return const SizedBox.shrink();

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size.infinite,
          painter: _WavesPainter(t: clamped),
        ),
      ),
    );
  }
}

class _RibbonSpec {
  const _RibbonSpec({
    required this.baseHeight,
    required this.amplitude,
    required this.speed,
    required this.phase,
    required this.colors,
    required this.alpha,
  });

  final double baseHeight;
  final double amplitude;
  final double speed;
  final double phase;
  final List<Color> colors;
  final double alpha;
}

class _WavesPainter extends CustomPainter {
  const _WavesPainter({required this.t});

  final double t;

  static final _ribbons = [
    _RibbonSpec(
      baseHeight: 0.86,
      amplitude: 0.05,
      speed: 0.55,
      phase: 0.0,
      colors: kSplashCtaGradient,
      alpha: 0.22,
    ),
    _RibbonSpec(
      baseHeight: 0.93,
      amplitude: 0.04,
      speed: 0.4,
      phase: 0.9,
      colors: const [kSplashAccentStrong, kSplashAccent],
      alpha: 0.16,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final ribbon in _ribbons) {
      _paintRibbon(canvas, size, ribbon);
    }
  }

  void _paintRibbon(Canvas canvas, Size size, _RibbonSpec ribbon) {
    final baseY = size.height * ribbon.baseHeight;
    final amplitude = size.height * ribbon.amplitude;
    final shift = t * ribbon.speed * 2 * math.pi;

    double waveY(double x) {
      final normalized = x / size.width;
      return baseY +
          math.sin((normalized * 2 * math.pi) + shift + ribbon.phase) *
              amplitude;
    }

    final path = Path()..moveTo(0, waveY(0));
    const steps = 24;
    for (var i = 1; i <= steps; i++) {
      final x = size.width * i / steps;
      final prevX = size.width * (i - 1) / steps;
      final midX = (prevX + x) / 2;
      path.quadraticBezierTo(midX, waveY(midX), x, waveY(x));
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        ribbon.colors.first.withValues(alpha: ribbon.alpha),
        ribbon.colors.last.withValues(alpha: ribbon.alpha),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final glowPaint = Paint()
      ..color = ribbon.colors.last.withValues(alpha: ribbon.alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final strokePath = Path()..moveTo(0, waveY(0));
    for (var i = 1; i <= steps; i++) {
      final x = size.width * i / steps;
      final prevX = size.width * (i - 1) / steps;
      final midX = (prevX + x) / 2;
      strokePath.quadraticBezierTo(midX, waveY(midX), x, waveY(x));
    }
    canvas.drawPath(strokePath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.t != t;
}
