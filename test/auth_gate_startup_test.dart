import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/router.dart';
import 'package:finassist/app/theme/app_theme.dart';
import 'package:finassist/features/activity/presentation/providers/activity_controller.dart';
import 'package:finassist/features/auth/data/models/auth_user.dart';
import 'package:finassist/features/auth/data/repositories/auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';
import 'package:finassist/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:finassist/features/profile/presentation/providers/preferences_controller.dart';
import 'package:finassist/features/profile/presentation/providers/profile_controller.dart';
import 'package:finassist/features/profile/presentation/providers/profile_finance_controller.dart';

import 'support/pump_app.dart';

/// Covers the startup/offline fix at the `AuthGate` level: a stored session
/// that can't be verified against the backend must resolve straight to the
/// app (using the last-known cached user) rather than blocking everything
/// behind a global "couldn't connect" screen — that global gate should now
/// only appear in the rare case where no user was ever cached.
///
/// `MockAuthRepository` (used by every other widget test via `pumpApp`)
/// always resolves `noSession` and can't drive these paths, so this file
/// uses a small configurable fake instead.
const _demoUser = AuthUser(
  id: '1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@finassist.com',
  username: 'ada',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._results);

  final List<SessionRestoreResult> _results;
  int restoreCallCount = 0;

  @override
  Future<SessionRestoreResult> restoreSession() async {
    final index = restoreCallCount < _results.length
        ? restoreCallCount
        : _results.length - 1;
    restoreCallCount++;
    return _results[index];
  }

  @override
  Future<AuthUser> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<String?> refreshAccessToken() async => null;
}

/// `hasSeenOnboardingProvider`/`hasCompletedInitialSetupProvider` (read
/// whenever a result resolves to `unauthenticated`/`noSession`) are backed
/// by `flutter_secure_storage`, whose MethodChannel doesn't exist in a
/// widget-test environment — left unmocked, that read never resolves and
/// strands the test on `_AuthGateLoading` forever. Both pre-seeded "already
/// done" since neither onboarding nor the new-vs-returning-user routing is
/// what this file is testing — it's about the offline/session-restore
/// fallback landing on the main shell or Login, not Register.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

const _seededTrueKeys = {
  'has_seen_onboarding_v1',
  'has_completed_initial_setup_v1',
};

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async =>
        call.method == 'read' && _seededTrueKeys.contains(call.arguments['key'])
        ? 'true'
        : null,
  );
}

/// Same shell `pumpApp` builds (real `onGenerateRoute`, real theme,
/// every backend-facing repository faked so nothing needs actual network),
/// but with `authRepositoryProvider` swapped for [repository] instead of
/// `MockAuthRepository` so `restoreSession()`'s outcome can be driven
/// directly.
Future<void> _pumpFromAuthGate(
  WidgetTester tester,
  AuthRepository repository,
) async {
  _mockSecureStorage(TestWidgetsFlutterBinding.ensureInitialized());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        preferenceRepositoryProvider.overrideWithValue(
          FakePreferenceRepository(),
        ),
        activityLogRepositoryProvider.overrideWithValue(
          FakeActivityLogRepository(),
        ),
        documentRepositoryProvider.overrideWithValue(FakeDocumentRepository()),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.authGate,
        onGenerateRoute: onGenerateRoute,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a stored session the backend cannot verify resolves straight to the '
    'main shell from the cached user — no global connection-error screen',
    (tester) async {
      await _pumpFromAuthGate(
        tester,
        _FakeAuthRepository([
          const SessionRestoreResult.authenticated(_demoUser),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
      expect(find.textContaining("couldn't connect"), findsNothing);
      expect(find.text('Welcome back'), findsNothing);
    },
  );

  testWidgets(
    'the rare unavailable fallback (no cached user at all) shows a scoped '
    'retry — never a forced Login — and "Try again" retries the same '
    'restore operation',
    (tester) async {
      final repo = _FakeAuthRepository([
        const SessionRestoreResult.unavailable(),
        const SessionRestoreResult.authenticated(_demoUser),
      ]);
      await _pumpFromAuthGate(tester, repo);
      await tester.pumpAndSettle();

      expect(find.textContaining("couldn't connect"), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mainShellScreen')), findsOneWidget);
      expect(repo.restoreCallCount, 2);
    },
  );

  testWidgets(
    'no stored session at all goes straight to Login — no global error and '
    'no backend dependency',
    (tester) async {
      await _pumpFromAuthGate(
        tester,
        _FakeAuthRepository([const SessionRestoreResult.noSession()]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.textContaining("couldn't connect"), findsNothing);
    },
  );
}
