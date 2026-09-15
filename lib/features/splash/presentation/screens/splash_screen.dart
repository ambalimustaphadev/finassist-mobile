import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/router.dart';
import '../splash_timeline.dart';
import '../widgets/splash_background_scene.dart';
import '../widgets/splash_feature_cards.dart';
import '../widgets/splash_logo_mark.dart';
import '../widgets/splash_orbit_layer.dart';
import '../widgets/splash_progress_bar.dart';
import '../widgets/splash_waves.dart';
import '../widgets/splash_wordmark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashTimeline.totalDuration,
    );
    _controller.forward();
    _controller.addStatusListener(_handleStatusChange);
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await Future<void>.delayed(SplashTimeline.completionHold);
    if (!mounted) return;
    // Named route (not a raw MaterialPageRoute) so this goes through the
    // same AuthGate every other entry point uses, and pushReplacementNamed
    // (not push) so Splash is actually removed from history.
    Navigator.of(context).pushReplacementNamed(AppRoutes.authGate);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final clusterSize = (width * 0.78).clamp(240.0, 340.0);
    final logoSize = clusterSize * 0.32;

    return Semantics(
      label: 'FinAssist is loading',
      child: MediaQuery(
        // Respects a larger system text size without letting it blow up
        // this tightly-composed screen.
        data: mediaQuery.copyWith(
          textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.15),
        ),
        // Light status-bar/nav-bar icons for this screen's near-black
        // background — the system bars themselves are transparent (see
        // `main.dart`), so only their icon color needs to be set here.
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    SplashBackgroundScene(t: t),
                    SplashWaves(t: t),
                    SafeArea(
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          SizedBox.square(
                            dimension: clusterSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SplashOrbitLayer(
                                  t: t,
                                  size: Size.square(clusterSize * 0.86),
                                ),
                                SplashFeatureCards(t: t, size: clusterSize),
                                SplashLogoMark(t: t, size: logoSize),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          SplashWordmark(t: t),
                          const Spacer(flex: 6),
                          SplashProgressBar(t: t),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
