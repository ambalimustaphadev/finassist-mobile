import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../splash_colors.dart';
import '../splash_timeline.dart';

/// The subtle glowing orbit around the logo/card cluster: a tilted ellipse
/// that draws itself in, gently rotates, and carries one small glowing
/// particle along its path — deliberately restrained so it frames the
/// cluster rather than competing with it.
class SplashOrbitLayer extends StatelessWidget {
  const SplashOrbitLayer({super.key, required this.t, required this.size});

  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final drawProgress = SplashTimeline.orbitDraw.transform(clamped);
    if (drawProgress <= 0.001) return const SizedBox.shrink();

    final particleProgress = SplashTimeline.orbitParticle.transform(clamped);
    // A slow, continuous tilt so the ring reads as "gently rotating"
    // rather than static, once it has fully drawn in.
    final rotation = drawProgress >= 0.999 ? clamped * 0.35 : 0.0;

    return IgnorePointer(
      child: Transform.rotate(
        angle: rotation,
        child: CustomPaint(
          size: size,
          painter: _OrbitPainter(
            drawProgress: drawProgress,
            particleProgress: particleProgress,
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.drawProgress,
    required this.particleProgress,
  });

  final double drawProgress;
  final double particleProgress;

  static const _startAngle = -math.pi / 2;
  static const _tilt = -0.12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.98,
      height: size.height * 0.56,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_tilt);
    canvas.translate(-center.dx, -center.dy);

    // Wide, soft glow duplicate beneath the crisp ring for bloom.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = kSplashAccentStrong.withValues(alpha: 0.16 * drawProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      rect,
      _startAngle,
      2 * math.pi * drawProgress,
      false,
      glowPaint,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = kSplashAccentSoft.withValues(alpha: 0.5 * drawProgress);
    canvas.drawArc(
      rect,
      _startAngle,
      2 * math.pi * drawProgress,
      false,
      ringPaint,
    );

    // A bit more than a full turn per pass so the particle's travel never
    // reads as a constant-speed mechanical loop.
    final angle = _startAngle + (2 * math.pi * 1.15 * particleProgress);
    final particleCenter = _pointOnEllipse(rect, angle);

    canvas.drawCircle(
      particleCenter,
      4,
      Paint()
        ..color = kSplashAccentSoft.withValues(alpha: 0.9 * drawProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      particleCenter,
      1.8,
      Paint()..color = Colors.white.withValues(alpha: 0.95 * drawProgress),
    );

    canvas.restore();
  }

  Offset _pointOnEllipse(Rect rect, double angle) {
    return rect.center +
        Offset(
          math.cos(angle) * rect.width / 2,
          math.sin(angle) * rect.height / 2,
        );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.particleProgress != particleProgress;
  }
}
