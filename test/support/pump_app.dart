import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/router.dart';
import 'package:finassist/app/theme/app_theme.dart';
import 'package:finassist/core/services/statement_file_picker_service.dart';
import 'package:finassist/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';

/// `flutter_secure_storage` talks to native code over a MethodChannel that
/// doesn't exist in a widget-test environment. Left unmocked, a call on it
/// never resolves — which, since `LocalConversationStore` (backing the
/// chat feature's recent-conversations list) reads from it on every
/// `ChatController` construction regardless of whether `chatRepositoryProvider`
/// itself is mocked, would otherwise strand the chat screen on its loading
/// state forever. Mocked here, once, so every test that goes through
/// `pumpApp` gets a working (if empty) in-memory store.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  final values = <String, String>{};
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return values[call.arguments['key']];
        case 'write':
          values[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'delete':
          values.remove(call.arguments['key']);
          return null;
        default:
          return null;
      }
    },
  );
}

/// Shared test helpers.
///
/// The real app now opens on a splash screen (`AppRoutes.splash`) that
/// requires a tap/swipe to continue and, once dismissed, runs an infinite
/// arrow animation — both are awkward to drive in a widget test and are
/// out of scope to change here. Tests instead build the same
/// `onGenerateRoute`/theme the app uses but start at `AppRoutes.authGate`
/// directly, exercising the real Login/Register/Dashboard code exactly as
/// `AuthGate` renders it, just skipping the splash screen's own animation.
///
/// `authRepositoryProvider` also now points at a live backend by default —
/// tests always override it with `MockAuthRepository` so they don't depend
/// on network.

/// Pumps the app (bypassing the splash screen) with sensible default
/// overrides — `authRepositoryProvider` mocked, plus any test-specific
/// [overrides] — and settles.
Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  _mockSecureStorage(TestWidgetsFlutterBinding.ensureInitialized());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.authGate,
        onGenerateRoute: onGenerateRoute,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Polls until [finder] matches something, up to `maxTries * 150ms`. Needed
/// wherever `pumpAndSettle()` would be unsafe (an infinite animation is on
/// screen) or a widget is outside the currently-built lazy-list range.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxTries = 40,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 150));
  }
}

class FakeStatementFilePickerService implements StatementFilePickerService {
  @override
  Future<PickedFile?> pickStatementFile() async {
    return const PickedFile(
      name: 'GTBank_Statement.pdf',
      extension: 'pdf',
      sizeBytes: 245000,
    );
  }
}

/// Logs in with `MockAuthRepository`'s seeded demo account and waits for
/// the dashboard to render.
Future<void> loginWithDemoAccount(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'demo@finassist.com');
  await tester.enterText(fields.at(1), 'password123');
  await tester.pump();
  await tester.tap(find.text('Login'));
  await pumpUntil(tester, find.byKey(const Key('dashboardScrollView')));
}
