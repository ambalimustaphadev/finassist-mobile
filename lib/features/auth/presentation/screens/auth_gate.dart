import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/local/onboarding_store.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../onboarding/presentation/screens/personalization_flow_screen.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../shell/presentation/providers/shell_providers.dart';
import '../../../shell/presentation/screens/main_shell_screen.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_state.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// The app's root: reactively shows the main shell (landing on Chat) once
/// a session is restored/authenticated, Login when there's none, a
/// bounded loading state while restoration is in flight, or a "couldn't
/// connect" state with a retry when a stored session exists but the
/// server can't be reached — restoring a session always resolves (see
/// `_restoreTimeout` in `ApiAuthRepository`), so this never hangs
/// indefinitely.
///
/// The unauthenticated and authenticated branches each have a one-time gate
/// in front of them ([_UnauthenticatedGate] for onboarding,
/// [_AuthenticatedGate] for the post-login profile setup) rather than a
/// new route/`AppRoutes` entry, so the existing raw-`Navigator` structure
/// stays untouched.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      authControllerProvider.select((state) => state.status),
    );

    // mainTabProvider isn't session-scoped — it just remembers the last
    // tab that was on screen. Without this, logging back in after logging
    // out while on e.g. Profile would silently reopen on Profile instead
    // of Chat. Resetting it exactly when a session becomes authenticated
    // (login, register+auto-sign-in, and restored sessions alike)
    // guarantees Chat — FinAssist's landing destination — is always the
    // tab shown.
    ref.listen(authControllerProvider.select((state) => state.status), (
      previous,
      next,
    ) {
      if (next == AuthStatus.authenticated) {
        ref.read(mainTabProvider.notifier).state = chatTabIndex;
      }
    });

    return switch (status) {
      AuthStatus.authenticated => const _AuthenticatedGate(),
      AuthStatus.unauthenticated => const _UnauthenticatedGate(),
      AuthStatus.unknown => const _AuthGateLoading(),
      AuthStatus.unavailable => const _AuthGateUnavailable(),
    };
  }
}

/// Shows the 3-page onboarding intro exactly once (ever), then routes to
/// either Register or Login depending on whether this device has ever
/// actually completed a real sign-in before ([hasCompletedInitialSetupProvider]
/// — set by `AuthController`, never by onboarding itself): a fresh or
/// dev-reset install (never signed in) goes to Register, since there's no
/// account yet to log into; a device that's done this before and is simply
/// logged out goes to Login. "Not authenticated" alone never implies "new
/// user" — that's what this second, independent flag is for. Fails open to
/// Login if either local check itself fails, since neither should ever be
/// able to block signing in.
class _UnauthenticatedGate extends ConsumerWidget {
  const _UnauthenticatedGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);
    final hasCompletedInitialSetup = ref.watch(
      hasCompletedInitialSetupProvider,
    );

    return hasSeenOnboarding.when(
      data: (seen) {
        if (!seen) return const OnboardingScreen();
        return hasCompletedInitialSetup.when(
          data: (completed) =>
              completed ? const LoginScreen() : const RegisterScreen(),
          loading: () => const _AuthGateLoading(),
          error: (_, _) => const LoginScreen(),
        );
      },
      loading: () => const _AuthGateLoading(),
      error: (_, _) => const LoginScreen(),
    );
  }
}

/// Shows the one-time, skippable 6-page personalization flow ahead of
/// Chat for a user whose real, backend-authoritative `onboarding_completed`
/// is still false — fails open to Chat if the profile load itself fails,
/// since setup is optional and should never be able to block access to
/// the app. Rendered directly (not pushed via `Navigator`), so the moment
/// `PersonalizationFlowScreen`'s completion step flips that flag true,
/// this reactively swaps straight to `MainShellScreen` with nothing left
/// to pop.
class _AuthenticatedGate extends ConsumerWidget {
  const _AuthenticatedGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    return switch (profileState.status) {
      ProfileLoadStatus.loading => const _AuthGateLoading(),
      ProfileLoadStatus.error => const MainShellScreen(),
      ProfileLoadStatus.loaded =>
        profileState.needsOnboarding
            ? const PersonalizationFlowScreen()
            : const MainShellScreen(),
    };
  }
}

class _AuthGateLoading extends StatelessWidget {
  const _AuthGateLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _AuthGateUnavailable extends ConsumerWidget {
  const _AuthGateUnavailable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(authControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "FinAssist couldn't connect right now.",
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      onTap: notifier.retryRestoreSession,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text(
                          'Try again',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: notifier.continueToLogin,
                  child: Text(
                    'Log in instead',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
