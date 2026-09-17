import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/onboarding_store.dart';
import '../widgets/onboarding_carousel_page.dart';

const _pageCount = 3;

/// The three-page FinAssist intro, shown once before the first Login —
/// `AuthGate` swaps this in for an unauthenticated session that hasn't
/// seen it yet, and never shows it again once dismissed (skip or finish).
/// All 3 pages share one dark, premium composition (`OnboardingCarouselPage`)
/// and only differ in content; this screen just owns paging and the
/// existing completion persistence.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingStoreProvider).markSeen();
    if (!mounted) return;
    ref.invalidate(hasSeenOnboardingProvider);
  }

  void _next() {
    if (_index == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Deliberately fixed-dark (not theme-reactive), like Splash — a
      // pre-auth brand moment shown before any theme preference is even
      // relevant.
      backgroundColor: const Color(0xFF0E1A15),
      body: PageView.builder(
        controller: _controller,
        itemCount: _pageCount,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => switch (i) {
          0 => OnboardingCarouselPage(
            asset: 'assets/onboarding/finassist_onboarding_chat.png',
            eyebrow: 'YOUR AI FINANCIAL PARTNER',
            headline: 'Make sense of your\nmoney with AI.',
            description:
                'Ask anything about your finances and get clear, '
                'personalized answers.',
            microcopy: 'ASK  —  UNDERSTAND  —  MAKE PROGRESS',
            pageIndex: 0,
            pageCount: _pageCount,
            onSkip: _finish,
            onPrimaryAction: _next,
          ),
          1 => OnboardingCarouselPage(
            asset: 'assets/onboarding/finassist_onboarding_documents.png',
            eyebrow: 'YOUR DOCUMENTS, CLEARER INSIGHTS',
            headline: 'Turn financial documents into\nclear answers.',
            description:
                'Upload statements, bills, and other documents and ask '
                'FinAssist to help you understand what matters.',
            microcopy: 'UPLOAD  —  ASK  —  GET CLARITY',
            pageIndex: 1,
            pageCount: _pageCount,
            onSkip: _finish,
            onPrimaryAction: _next,
          ),
          _ => OnboardingCarouselPage(
            asset: 'assets/onboarding/finassist_onboarding_tools.png',
            eyebrow: 'PRACTICAL TOOLS FOR REAL LIFE',
            headline: 'Ask. Understand.\nCalculate.',
            description:
                'Use powerful financial tools when you need a quick, '
                'practical calculation.',
            microcopy: 'EXPLORE  —  CALCULATE  —  TAKE ACTION',
            pageIndex: 2,
            pageCount: _pageCount,
            onSkip: _finish,
            onPrimaryAction: _finish,
            primarySemanticLabel: 'Get started',
            getStartedLabel: 'Get Started',
          ),
        },
      ),
    );
  }
}
