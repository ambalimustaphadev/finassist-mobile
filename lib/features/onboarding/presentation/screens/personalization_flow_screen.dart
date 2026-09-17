import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/personalization_controller.dart';
import 'personalization_screen_complete.dart';
import 'personalization_screen_experience.dart';
import 'personalization_screen_interests.dart';
import 'personalization_screen_intro.dart';
import 'personalization_screen_response_style.dart';
import 'personalization_screen_situation.dart';

/// Hosts the personalization flow's 6 pages in one `PageView` —
/// `AuthGate` shows this directly (not pushed via `Navigator`) for any
/// authenticated session whose real, backend-authoritative
/// `onboarding_completed` is still false, so this stays as simple as the
/// rest of the app's raw-`Navigator` architecture: no new named route,
/// just a widget `AuthGate` swaps in and back out reactively.
class PersonalizationFlowScreen extends ConsumerStatefulWidget {
  const PersonalizationFlowScreen({super.key});

  @override
  ConsumerState<PersonalizationFlowScreen> createState() =>
      _PersonalizationFlowScreenState();
}

class _PersonalizationFlowScreenState
    extends ConsumerState<PersonalizationFlowScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _completeIndex = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() => _goTo(_index + 1);

  void _back() {
    if (_index == 0) return;
    _goTo(_index - 1);
  }

  /// Jumps straight to the completion page without saving anything yet —
  /// the same "answer as much or as little as you like" behavior the
  /// flow has always had. Nothing is persisted until the user actually
  /// taps "Continue to FinAssist" there.
  void _skip() => _goTo(_completeIndex);

  /// Lets the completion page's "Edit" return to the first real question
  /// (Page 2 — the introduction has nothing to edit) without resetting
  /// any answer already given.
  void _edit() => _goTo(1);

  Future<void> _finish() async {
    final ok = await ref
        .read(personalizationControllerProvider.notifier)
        .completeSetup();
    // No manual navigation on success — `AuthGate` reactively watches
    // `profileControllerProvider` and swaps this screen out for Chat
    // itself once `onboardingCompleted` flips true above.
    if (!mounted || !ok) return;
  }

  @override
  Widget build(BuildContext context) {
    // None of the question screens have inline error UI of their own — a
    // scoped SnackBar covers "Continue to FinAssist" failing without
    // inventing a second error-display pattern.
    ref.listen(personalizationControllerProvider.select((s) => s.saveError), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.surfaceElevated,
            content: Text(
              next,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: context.colors.accent,
              onPressed: _finish,
            ),
          ),
        );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          PersonalizationIntroScreen(onSkip: _skip, onContinue: _next),
          PersonalizationSituationScreen(
            onBack: _back,
            onSkip: _skip,
            onContinue: _next,
          ),
          PersonalizationExperienceScreen(
            onBack: _back,
            onSkip: _skip,
            onContinue: _next,
          ),
          PersonalizationInterestsScreen(
            onBack: _back,
            onSkip: _skip,
            onContinue: _next,
          ),
          PersonalizationResponseStyleScreen(
            onBack: _back,
            onSkip: _skip,
            onContinue: _next,
          ),
          PersonalizationCompleteScreen(
            onBack: _back,
            onEdit: _edit,
            onContinue: _finish,
          ),
        ],
      ),
    );
  }
}
