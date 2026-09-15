import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/router.dart';
import 'package:finassist/app/theme/app_theme.dart';
import 'package:finassist/core/network/pagination.dart';
import 'package:finassist/core/services/statement_file_picker_service.dart';
import 'package:finassist/features/activity/data/models/activity_log_entry.dart';
import 'package:finassist/features/activity/data/repositories/activity_log_repository.dart';
import 'package:finassist/features/activity/presentation/providers/activity_controller.dart';
import 'package:finassist/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';
import 'package:finassist/features/auth/presentation/widgets/auth_checkbox.dart';
import 'package:finassist/features/notifications/data/models/notification.dart';
import 'package:finassist/features/notifications/data/repositories/notification_repository.dart';
import 'package:finassist/features/notifications/presentation/providers/notifications_controller.dart';
import 'package:finassist/features/profile/data/models/preferences.dart';
import 'package:finassist/features/profile/data/models/profile.dart';
import 'package:finassist/features/profile/data/models/uploaded_file.dart';
import 'package:finassist/features/profile/data/models/uploaded_statement.dart';
import 'package:finassist/features/profile/data/repositories/document_repository.dart';
import 'package:finassist/features/profile/data/repositories/file_upload_repository.dart';
import 'package:finassist/features/profile/data/repositories/preference_repository.dart';
import 'package:finassist/features/profile/data/repositories/profile_repository.dart';
import 'package:finassist/features/profile/presentation/providers/preferences_controller.dart';
import 'package:finassist/features/profile/presentation/providers/profile_controller.dart';
import 'package:finassist/features/profile/presentation/providers/profile_finance_controller.dart';
import 'package:finassist/features/subscriptions/data/models/subscription.dart';
import 'package:finassist/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:finassist/features/subscriptions/presentation/providers/subscription_controller.dart';

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

void _mockSecureStorage(
  TestWidgetsFlutterBinding binding,
  Map<String, String> initialValues,
) {
  final values = Map<String, String>.from(initialValues);
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
/// directly, exercising the real Login/Register/Chat code exactly as
/// `AuthGate` renders it, just skipping the splash screen's own animation.
///
/// `authRepositoryProvider` also now points at a live backend by default —
/// tests always override it with `MockAuthRepository` so they don't depend
/// on network.

/// Pumps the app (bypassing the splash screen) with sensible default
/// overrides — `authRepositoryProvider` mocked, plus any test-specific
/// [overrides] — and settles.
///
/// [skipOnboarding] pre-seeds the mocked secure storage so the vast
/// majority of tests (which care about Login/Register/Chat behavior,
/// not the pre-login onboarding intro itself) land exactly where they did
/// before that gate existed. The post-login profile-setup gate is driven
/// by the real, backend-authoritative `onboardingCompleted` now — tests
/// that need to see `PersonalizationFlowScreen` should pass a
/// [profileRepository] seeded with `onboardingCompleted: false` instead.
///
/// [hasCompletedInitialSetup] similarly pre-seeds "this device has signed
/// in before" so the same vast majority of tests keep landing on Login
/// (not Register) by default — tests exercising the fresh/reset-device ->
/// Register routing should pass `false` instead.
Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  bool skipOnboarding = true,
  bool hasCompletedInitialSetup = true,
  ProfileRepository? profileRepository,
  PreferenceRepository? preferenceRepository,
  ActivityLogRepository? activityLogRepository,
  DocumentRepository? documentRepository,
  NotificationRepository? notificationRepository,
  SubscriptionRepository? subscriptionRepository,
}) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  _mockSecureStorage(binding, {
    if (skipOnboarding) 'has_seen_onboarding_v1': 'true',
    if (hasCompletedInitialSetup) 'has_completed_initial_setup_v1': 'true',
  });
  _mockPathProvider(binding);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        profileRepositoryProvider.overrideWithValue(
          profileRepository ?? FakeProfileRepository(),
        ),
        preferenceRepositoryProvider.overrideWithValue(
          preferenceRepository ?? FakePreferenceRepository(),
        ),
        activityLogRepositoryProvider.overrideWithValue(
          activityLogRepository ?? FakeActivityLogRepository(),
        ),
        documentRepositoryProvider.overrideWithValue(
          documentRepository ?? FakeDocumentRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          notificationRepository ?? FakeNotificationRepository(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          subscriptionRepository ?? FakeSubscriptionRepository(),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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

/// Swap for `profileRepositoryProvider` — in-memory, always succeeds,
/// seeded to match `MockAuthRepository`'s demo account by default so
/// `ProfileHeaderCard` displays real-looking data without any test
/// needing to know about the profile feature at all.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({Profile? initialProfile})
    : _profile = initialProfile ?? _defaultProfile();

  Profile _profile;

  static Profile _defaultProfile() {
    final now = DateTime(2026, 1, 1);
    return Profile(
      id: 1,
      username: 'mustapha',
      firstName: 'Mustapha',
      lastName: 'Ambali',
      email: 'demo@finassist.com',
      currency: 'NGN',
      onboardingCompleted: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Profile> getProfile() async => _profile;

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) async {
    _profile = Profile(
      id: _profile.id,
      username: _profile.username,
      firstName: changes['first_name'] as String? ?? _profile.firstName,
      lastName: changes['last_name'] as String? ?? _profile.lastName,
      email: _profile.email,
      country: changes.containsKey('country')
          ? changes['country'] as String?
          : _profile.country,
      currency: changes['currency'] as String? ?? _profile.currency,
      occupation: changes.containsKey('occupation')
          ? changes['occupation'] as String?
          : _profile.occupation,
      employmentStatus: changes.containsKey('employment_status')
          ? changes['employment_status'] as String?
          : _profile.employmentStatus,
      income: changes.containsKey('income')
          ? (changes['income'] as num?)?.toDouble()
          : _profile.income,
      incomeFrequency: changes.containsKey('income_frequency')
          ? changes['income_frequency'] as String?
          : _profile.incomeFrequency,
      profilePictureUrl: _profile.profilePictureUrl,
      onboardingCompleted:
          changes['onboarding_completed'] as bool? ??
          _profile.onboardingCompleted,
      createdAt: _profile.createdAt,
      updatedAt: DateTime.now(),
    );
    return _profile;
  }

  @override
  Future<Profile> uploadProfilePicture(File file) async {
    _profile = Profile(
      id: _profile.id,
      username: _profile.username,
      firstName: _profile.firstName,
      lastName: _profile.lastName,
      email: _profile.email,
      country: _profile.country,
      currency: _profile.currency,
      occupation: _profile.occupation,
      employmentStatus: _profile.employmentStatus,
      income: _profile.income,
      incomeFrequency: _profile.incomeFrequency,
      profilePictureUrl:
          'https://pub-test.r2.dev/profile-pictures/${_profile.id}/fake.jpg',
      onboardingCompleted: _profile.onboardingCompleted,
      createdAt: _profile.createdAt,
      updatedAt: DateTime.now(),
    );
    return _profile;
  }
}

/// Swap for `preferenceRepositoryProvider` — in-memory, always succeeds,
/// seeded to the same NGN/English defaults the real backend returns for a
/// brand-new `UserPreference` row.
class FakePreferenceRepository implements PreferenceRepository {
  FakePreferenceRepository({Preferences? initialPreferences})
    : _preferences = initialPreferences ?? _defaultPreferences();

  Preferences _preferences;

  static Preferences _defaultPreferences() {
    return Preferences(
      currency: 'NGN',
      language: 'en',
      notificationsEnabled: true,
      documentNotifications: true,
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<Preferences> getPreferences() async => _preferences;

  @override
  Future<Preferences> updatePreferences(Map<String, dynamic> changes) async {
    _preferences = Preferences(
      currency: changes['currency'] as String? ?? _preferences.currency,
      language: changes['language'] as String? ?? _preferences.language,
      notificationsEnabled:
          changes['notifications_enabled'] as bool? ??
          _preferences.notificationsEnabled,
      documentNotifications:
          changes['document_notifications'] as bool? ??
          _preferences.documentNotifications,
      financialExperience:
          changes['financial_experience'] as String? ??
          _preferences.financialExperience,
      interests:
          (changes['interests'] as List?)
              ?.map((interest) => interest as String)
              .toList() ??
          _preferences.interests,
      responseStyle:
          changes['response_style'] as String? ?? _preferences.responseStyle,
      proactiveSuggestions:
          changes['proactive_suggestions'] as bool? ??
          _preferences.proactiveSuggestions,
      updatedAt: DateTime.now(),
    );
    return _preferences;
  }
}

/// Swap for `activityLogRepositoryProvider` — in-memory, always succeeds.
/// Stateful (unlike the other fakes' simple defaults) so a test that posts
/// a calculator run via `logActivity` and then reads the Activity tab sees
/// it come back, exactly like the real backend round-trip would.
class FakeActivityLogRepository implements ActivityLogRepository {
  FakeActivityLogRepository({List<ActivityLogEntry>? initialEntries})
    : _entries = List.of(initialEntries ?? const []);

  final List<ActivityLogEntry> _entries;
  int _nextId = 1;

  @override
  Future<List<ActivityLogEntry>> getActivity() async => List.of(_entries);

  @override
  Future<void> logActivity({
    required String type,
    required String title,
    String? description,
  }) async {
    _entries.insert(
      0,
      ActivityLogEntry(
        id: _nextId++,
        type: type,
        title: title,
        description: description,
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Swap for `fileUploadRepositoryProvider` in tests that need the upload
/// step to succeed without touching a real HTTP client — mirrors
/// `MockChatRepository`'s "always succeeds" role for the chat repository.
///
/// [activityLogRepository], when given, is written to on a successful
/// upload — mirroring the real backend's `file_routes.py`, which logs a
/// real `document_uploaded` Activity row as a side effect of the upload
/// endpoint itself (Flutter never posts this type directly).
class FakeFileUploadRepository implements FileUploadRepository {
  FakeFileUploadRepository({ActivityLogRepository? activityLogRepository})
    : _activityLogRepository = activityLogRepository;

  final ActivityLogRepository? _activityLogRepository;

  @override
  Future<UploadedFile> uploadFile(File file) async {
    const uploaded = UploadedFile(
      id: 1,
      filename: 'GTBank_Statement.pdf',
      size: 245000,
      contentType: 'application/pdf',
    );
    await _activityLogRepository?.logActivity(
      type: 'document_uploaded',
      title: 'Uploaded ${uploaded.filename}',
    );
    return uploaded;
  }
}

/// Swap for `documentRepositoryProvider` — in-memory, always succeeds,
/// starts empty (a brand-new account has no documents) unless seeded.
/// [perPage] lets a test exercise `loadMore` pagination without a real
/// backend.
class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({List<UploadedStatement>? seed, this.perPage = 20})
    : _files = List.of(seed ?? const []);

  final List<UploadedStatement> _files;
  final int perPage;

  @override
  Future<Paginated<UploadedStatement>> listFiles({int page = 1}) async {
    final start = (page - 1) * perPage;
    final items = start >= _files.length
        ? const <UploadedStatement>[]
        : _files.sublist(start, (start + perPage).clamp(0, _files.length));
    return Paginated(
      items: items,
      pagination: Pagination(
        page: page,
        perPage: perPage,
        total: _files.length,
      ),
    );
  }

  @override
  Future<void> deleteFile(int id) async {
    _files.removeWhere((f) => f.backendId == id);
  }

  @override
  Future<String> getViewUrl(int fileId) async {
    return 'https://pub-test.r2.dev/signed/$fileId';
  }
}

/// Swap for `notificationRepositoryProvider` — in-memory, always succeeds,
/// starts empty (the honest default, matching the real backend having no
/// creation trigger yet) unless seeded.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({List<AppNotification>? seed})
    : _notifications = List.of(seed ?? const []);

  final List<AppNotification> _notifications;

  @override
  Future<Paginated<AppNotification>> getNotifications({int page = 1}) async {
    return Paginated(
      items: List.of(_notifications),
      pagination: Pagination(
        page: page,
        perPage: 20,
        total: _notifications.length,
      ),
    );
  }

  @override
  Future<void> markRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(read: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
  }
}

/// Swap for `subscriptionRepositoryProvider` — in-memory, always succeeds,
/// starts empty unless seeded. Builds/merges plain JSON maps through
/// `Subscription.fromJson` (rather than hand-writing a second constructor
/// path) so it stays honest to the real `subscription_to_dict()` shape.
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({List<Subscription>? seed})
    : _subscriptions = List.of(seed ?? const []);

  final List<Subscription> _subscriptions;
  int _nextId = 1000;

  Map<String, dynamic> _toJson(Subscription s) => {
    'id': s.id,
    'user_id': s.userId,
    'name': s.name,
    'amount': s.amount,
    'currency': s.currency,
    'frequency': s.frequency.apiValue,
    'next_billing_date': s.nextBillingDate.toIso8601String().split('T').first,
    'category': s.category?.apiValue,
    'payment_method': s.paymentMethod?.apiValue,
    'website': s.website,
    'notes': s.notes,
    'status': s.status.apiValue,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': s.updatedAt.toIso8601String(),
    'cancelled_at': s.cancelledAt?.toIso8601String(),
  };

  @override
  Future<List<Subscription>> getSubscriptions() async => List.of(_subscriptions);

  @override
  Future<Subscription> getSubscription(int id) async {
    return _subscriptions.firstWhere((s) => s.id == id);
  }

  @override
  Future<Subscription> createSubscription(Map<String, dynamic> body) async {
    final now = DateTime.now();
    final created = Subscription.fromJson({
      ..._toJson(
        Subscription(
          id: _nextId++,
          userId: 1,
          name: '',
          amount: 0,
          currency: 'NGN',
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: now,
          status: SubscriptionStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      ),
      ...body,
      'status': 'active',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'cancelled_at': null,
    });
    _subscriptions.add(created);
    return created;
  }

  @override
  Future<Subscription> updateSubscription(
    int id,
    Map<String, dynamic> changes,
  ) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    final existing = _subscriptions[index];
    final merged = {
      ..._toJson(existing),
      ...changes,
      'updated_at': DateTime.now().toIso8601String(),
      if (changes['status'] == 'cancelled')
        'cancelled_at': DateTime.now().toIso8601String()
      else if (changes.containsKey('status'))
        'cancelled_at': null,
    };
    final updated = Subscription.fromJson(merged);
    _subscriptions[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSubscription(int id) async {
    _subscriptions.removeWhere((s) => s.id == id);
  }
}

/// Logs in with `MockAuthRepository`'s seeded demo account and waits for
/// the main shell (landing on the Chat tab) to render.
Future<void> loginWithDemoAccount(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'demo@finassist.com');
  await tester.enterText(fields.at(1), 'password123');
  await tester.pump();
  await tester.tap(find.text('Login'));
  await pumpUntil(tester, find.byKey(const Key('mainShellScreen')));
}

/// Fills and submits the Register form (assumes it's already on screen)
/// with a brand-new account, agrees to terms, waits for the real
/// `POST /api/register` + auto-sign-in round trip, then dismisses the
/// "Account Created" screen — leaves the tester wherever `AuthGate`
/// reactively lands next (Chat, or `PersonalizationFlowScreen` for a
/// profile that still needs it), same as a real device.
Future<void> registerNewAccount(
  WidgetTester tester, {
  String firstName = 'Ada',
  String lastName = 'Lovelace',
  String email = 'ada@finassist.com',
  String username = 'adalovelace',
  String password = 'securePass1',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), firstName);
  await tester.enterText(fields.at(1), lastName);
  await tester.enterText(fields.at(2), email);
  await tester.enterText(fields.at(3), username);
  await tester.enterText(fields.at(4), password);
  await tester.enterText(fields.at(5), password);
  final checkbox = find.byType(AuthCheckbox);
  await tester.ensureVisible(checkbox);
  await tester.pump();
  await tester.tap(checkbox);
  await tester.pump();
  final createAccountButton = find.text('Create account');
  await tester.ensureVisible(createAccountButton);
  await tester.pump();
  await tester.tap(createAccountButton);
  await pumpUntil(
    tester,
    find.text('Account Created\nSuccessfully!', findRichText: true),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}
