import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// The shared light-surface shell for every pre-authentication screen
/// (Login, Register) — off-white background matching the rest of
/// FinAssist's light surfaces (onboarding), a back arrow shown only when
/// there's actually somewhere to go back to, and a scrollable, keyboard-safe
/// body so no field or button is ever hidden behind the keyboard.
///
/// The back arrow is deliberately conditional on [ModalRoute.canPopOf]
/// rather than a fixed per-screen flag: Login has nothing to pop to when
/// it's `AuthGate`'s unauthenticated root (reached directly from Splash),
/// but does when reached by popping back from Register — same screen,
/// correct affordance either way, with no separate "is this the root"
/// plumbing.
///
/// This must be [ModalRoute.canPopOf], not `Navigator.of(context).canPop()`
/// — the latter is a plain imperative getter read that creates no rebuild
/// dependency, so after Register pops back to Login, Login's already-built
/// widget (built the first time it was covered by Register, when canPop
/// really was true) never re-evaluates it and keeps showing a stale back
/// arrow over what is now the root route. `ModalRoute.canPopOf` reads
/// through an `InheritedModel` that the Navigator explicitly notifies on
/// every push/pop, so this widget rebuilds exactly when the answer changes.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.canPopOf(context) ?? false;

    // Dark status-bar/nav-bar icons for this screen's light background —
    // the system bars themselves are transparent (see `main.dart`), so
    // only their icon color needs to be set here.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.onboardingBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canPop)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Semantics(
                    button: true,
                    label: 'Back',
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.onboardingHeading,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        canPop ? AppSpacing.sm : AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              AppSpacing.xl -
                              (canPop ? AppSpacing.sm : AppSpacing.xl),
                        ),
                        child: builder(context),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
