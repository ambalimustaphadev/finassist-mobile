import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _pulse;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _buttonOpacity;
  late final Animation<Offset> _buttonSlide;

  bool _showGetStarted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOutBack),
      ),
    );

    _pulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.62, curve: Curves.easeInOut),
    );

    _nameOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.68, curve: Curves.easeOut),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.82, curve: Curves.easeOut),
    );

    _buttonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
    );

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward().whenComplete(() {
      if (!mounted) return;

      setState(() {
        _showGetStarted = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // The mark/name/tagline block is anchored with `Align(center)` so it
      // sits at the exact center of the available (SafeArea) space on any
      // screen size, independent of the "Get started" control pinned below
      // it — a fixed-ratio Spacer split would bias it toward one edge
      // instead of the true center.
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  key: const Key('splashCenterBlock'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: _FinAssistMark(pulse: _pulse.value),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    AnimatedBuilder(
                      animation: _nameOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _nameOpacity.value,
                          child: const Text(
                            'FinAssist',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    AnimatedBuilder(
                      animation: _taglineOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _taglineOpacity.value,
                          child: Text(
                            'Your money, understood.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.58),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        if (!_showGetStarted) {
                          return const SizedBox(height: 98);
                        }

                        return FadeTransition(
                          opacity: _buttonOpacity,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: const _GetStartedButton(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        if (!_showGetStarted) {
                          return const SizedBox(height: 18);
                        }

                        return Opacity(
                          opacity: _buttonOpacity.value,
                          child: Text(
                            'Swipe to continue',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.42),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
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

class _GetStartedButton extends StatefulWidget {
  const _GetStartedButton();

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
    with TickerProviderStateMixin {
  double _dragOffset = 0;
  bool _completed = false;

  late final AnimationController _arrowController;
  late final AnimationController _snapBackController;
  Animation<double>? _snapBackAnimation;

  static const double _maxDrag = 120;

  /// A deliberately high fraction of [_maxDrag] — this is a swipe-to-confirm
  /// control, not a tap target, so an accidental brush of the arrow should
  /// never complete it.
  static const double _completionThreshold = 96;

  @override
  void initState() {
    super.initState();

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _snapBackController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          final animation = _snapBackAnimation;
          if (animation == null) return;
          setState(() => _dragOffset = animation.value);
        });
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    if (!mounted) return;

    // Named route (not a raw MaterialPageRoute) so this goes through the
    // same AuthGate every other entry point uses, and pushReplacementNamed
    // (not push) so Splash is actually removed from history — otherwise it
    // lingers underneath Login and the first back-swipe gesture briefly
    // reveals/transitions through it before settling.
    Navigator.of(context).pushReplacementNamed(AppRoutes.authGate);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_completed) return;
    _snapBackController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_completed) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_completed) return;

    if (_dragOffset >= _completionThreshold) {
      setState(() => _completed = true);
      _goToLogin();
      return;
    }

    _snapBack();
  }

  /// Smoothly eases the handle back to the start instead of snapping
  /// instantly — an incomplete swipe should feel like it was gently
  /// declined, not abruptly cancelled.
  void _snapBack() {
    _snapBackAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.easeOut),
    );
    _snapBackController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Get started',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            Positioned(
              left: 8,
              child: AnimatedBuilder(
                animation: _arrowController,
                builder: (context, child) {
                  final animationOffset =
                      math.sin(_arrowController.value * math.pi) * 4;

                  return Transform.translate(
                    offset: Offset(_dragOffset + animationOffset, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 21,
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

class _FinAssistMark extends StatelessWidget {
  const _FinAssistMark({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(painter: _FinAssistMarkPainter(pulse: pulse)),
    );
  }
}

class _FinAssistMarkPainter extends CustomPainter {
  const _FinAssistMarkPainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final radius = size.width * 0.34;

    // Outer subtle ring.
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.accent.withValues(alpha: 0.18);

    canvas.drawCircle(center, radius + 13, outerPaint);

    // Animated green ring.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;

    final startAngle = -math.pi / 2;

    final sweepAngle = math.pi * 1.65 * pulse;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      ringPaint,
    );

    // Soft inner glow.
    final innerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accent.withValues(alpha: 0.10 + (pulse * 0.10));

    canvas.drawCircle(center, radius - 5, innerPaint);

    // FinAssist "F".
    final fPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    final path = Path()
      ..moveTo(center.dx - 10, center.dy + 17)
      ..lineTo(center.dx - 10, center.dy - 17)
      ..lineTo(center.dx + 11, center.dy - 17)
      ..moveTo(center.dx - 10, center.dy - 2)
      ..lineTo(center.dx + 6, center.dy - 2);

    canvas.drawPath(path, fPaint);

    // Small AI/active indicator.
    final dotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx + radius * 0.72, center.dy - radius * 0.72),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FinAssistMarkPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}
