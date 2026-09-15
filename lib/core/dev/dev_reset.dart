import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../local/onboarding_store.dart';

/// Development-only: clears local auth + onboarding state so the app's
/// existing `AuthGate`/routing logic naturally resolves back to the
/// first-launch flow (Splash -> Onboarding -> Register), without touching
/// the backend or any server-side data.
///
/// Deliberately just [AuthController.logout] (the same local-only token
/// clear a real logout performs) plus [OnboardingStore.reset] (both the
/// onboarding-seen flag and the "has this device ever signed in" flag) —
/// no separate auth/routing path. The only caller (`ProfileScreen`'s
/// Development section) gates this behind `kDebugMode`.
Future<void> resetAppStateForDevelopment(WidgetRef ref) async {
  await ref.read(authControllerProvider.notifier).logout();
  await ref.read(onboardingStoreProvider).reset();
  ref.invalidate(hasSeenOnboardingProvider);
}
