import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/router.dart';
import 'package:finassist/app/theme/app_theme.dart';
import 'package:finassist/core/services/statement_file_picker_service.dart';
import 'package:finassist/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';
import 'package:finassist/features/profile/data/models/uploaded_file.dart';
import 'package:finassist/features/profile/data/repositories/file_upload_repository.dart';

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

/// `path_provider`'s MethodChannel doesn't exist in a widget-test
/// environment either — needed since `FakeStatementFilePickerService`'s
/// canned pick has no `path` (only `bytes`), so resolving it for an
/// upload falls back to `getTemporaryDirectory()`. Left unmocked, that
/// call would throw and every attach-then-send test would silently fail
/// to ever add the message.
const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void _mockPathProvider(TestWidgetsFlutterBinding binding) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _pathProviderChannel,
    (call) async => Directory.systemTemp.path,
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
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  _mockSecureStorage(binding);
  _mockPathProvider(binding);
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
    // A real widget test's `file_picker` result always carries a path
    // (or bytes) to actually read the file back from for an upload —
    // written here as a real temp file so a test exercising the real
    // upload path has something to resolve. Deliberately synchronous
    // (`writeAsBytesSync`, not the `Future`-returning variant): this
    // runs as a reaction to `tester.tap()` inside `WidgetTester.pump()`'s
    // controlled execution, where a genuinely-async `dart:io` operation
    // (one not driven by the test binding's own clock) never resolves —
    // a synchronous call has no such gap to get stuck in.
    final file = File(
      '${Directory.systemTemp.path}/GTBank_Statement_${DateTime.now().microsecondsSinceEpoch}.pdf',
    )..writeAsBytesSync(utf8.encode('%PDF-1.4 fake statement'));

    return PickedFile(
      name: 'GTBank_Statement.pdf',
      extension: 'pdf',
      sizeBytes: 245000,
      path: file.path,
    );
  }
}

/// Swap for `fileUploadRepositoryProvider` in tests that need the upload
/// step to succeed without touching a real HTTP client — mirrors
/// `MockChatRepository`'s "always succeeds" role for the chat repository.
class FakeFileUploadRepository implements FileUploadRepository {
  @override
  Future<UploadedFile> uploadFile(File file) async {
    return const UploadedFile(
      id: 1,
      filename: 'GTBank_Statement.pdf',
      size: 245000,
      contentType: 'application/pdf',
      key: 'statement/1/fake-uuid.pdf',
      fileUrl: 'https://pub-test.r2.dev/statement/1/fake-uuid.pdf',
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
