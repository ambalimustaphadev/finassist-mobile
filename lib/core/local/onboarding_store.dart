import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local, device-scoped flags `AuthGate` uses to route an unauthenticated
/// session — neither is per-user (both are checked before any account is
/// known), and neither is touched by a normal logout, only by [reset]
/// (dev-only, simulating a fresh install):
///
/// - [hasSeenOnboarding]: has the 3-page intro ever been shown (finished or
///   skipped)? Never replays once true.
/// - [hasCompletedInitialSetup]: has this device ever actually completed a
///   real sign-in? Distinguishes a fresh/reset install that's seen
///   onboarding but never created/signed into an account (-> Register) from
///   a device that has, and is simply logged out right now (-> Login).
class OnboardingStore {
  OnboardingStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _seenOnboardingKey = 'has_seen_onboarding_v1';
  static const _initialSetupKey = 'has_completed_initial_setup_v1';

  Future<bool> hasSeenOnboarding() async {
    final raw = await _storage.read(key: _seenOnboardingKey);
    return raw == 'true';
  }

  Future<void> markSeen() async {
    await _storage.write(key: _seenOnboardingKey, value: 'true');
  }

  Future<bool> hasCompletedInitialSetup() async {
    final raw = await _storage.read(key: _initialSetupKey);
    return raw == 'true';
  }

  /// Called by `AuthController` on every path that reaches
  /// [AuthStatus.authenticated] (including a fresh registration's own
  /// auto-sign-in) — never undone except by [reset].
  Future<void> markInitialSetupComplete() async {
    await _storage.write(key: _initialSetupKey, value: 'true');
  }

  /// Development-only: undoes [markSeen] and [markInitialSetupComplete] so
  /// the app resolves back to the first-launch flow (Onboarding ->
  /// Register), as on a genuinely fresh install. See
  /// `resetAppStateForDevelopment`.
  Future<void> reset() async {
    await _storage.delete(key: _seenOnboardingKey);
    await _storage.delete(key: _initialSetupKey);
  }
}

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => OnboardingStore(),
);

/// `autoDispose` so `AuthGate` re-checks fresh each time it's rebuilt from
/// scratch (e.g. a hot restart in dev) rather than caching a stale answer
/// across the whole app lifetime.
final hasSeenOnboardingProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(onboardingStoreProvider).hasSeenOnboarding();
});

/// Same `autoDispose` reasoning as [hasSeenOnboardingProvider].
final hasCompletedInitialSetupProvider = FutureProvider.autoDispose<bool>((
  ref,
) {
  return ref.watch(onboardingStoreProvider).hasCompletedInitialSetup();
});
