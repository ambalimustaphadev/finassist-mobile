import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/profile/data/models/preferences.dart';
import 'package:finassist/features/profile/data/repositories/preference_repository.dart';
import 'package:finassist/features/profile/presentation/providers/preferences_controller.dart';

class _FakeRepo implements PreferenceRepository {
  _FakeRepo({this.errorOnUpdate})
    : _preferences = Preferences(
        currency: 'NGN',
        language: 'en',
        notificationsEnabled: true,
        documentNotifications: true,
        updatedAt: DateTime(2026, 1, 1),
      );

  Preferences _preferences;
  final ApiException? errorOnUpdate;

  @override
  Future<Preferences> getPreferences() async => _preferences;

  @override
  Future<Preferences> updatePreferences(Map<String, dynamic> changes) async {
    if (errorOnUpdate != null) throw errorOnUpdate!;
    _preferences = Preferences(
      currency: changes['currency'] as String? ?? _preferences.currency,
      language: changes['language'] as String? ?? _preferences.language,
      notificationsEnabled: _preferences.notificationsEnabled,
      documentNotifications: _preferences.documentNotifications,
      updatedAt: DateTime.now(),
    );
    return _preferences;
  }
}

void main() {
  test('loads the real preferences on construction', () async {
    final controller = PreferencesController(_FakeRepo(), 'user-1');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, PreferencesLoadStatus.loaded);
    expect(controller.state.currency, 'NGN');
    expect(controller.state.language, 'en');
  });

  test('setCurrency updates state from the server response', () async {
    final controller = PreferencesController(_FakeRepo(), 'user-1');
    await Future<void>.delayed(Duration.zero);

    final success = await controller.setCurrency('USD');

    expect(success, isTrue);
    expect(controller.state.currency, 'USD');
    expect(controller.state.isSaving, isFalse);
  });

  test(
    'a failed update surfaces the error and leaves state unchanged',
    () async {
      final controller = PreferencesController(
        _FakeRepo(errorOnUpdate: const ApiException('Unsupported currency')),
        'user-1',
      );
      await Future<void>.delayed(Duration.zero);

      final success = await controller.setCurrency('XX');

      expect(success, isFalse);
      expect(controller.state.saveError, 'Unsupported currency');
      expect(controller.state.currency, 'NGN');
    },
  );

  test('a load failure surfaces a clear error, not a crash', () async {
    final controller = PreferencesController(_ThrowingLoadRepo(), 'user-1');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, PreferencesLoadStatus.error);
    expect(controller.state.loadError, isNotNull);
    // Falls back to sensible defaults rather than leaving callers with null.
    expect(controller.state.currency, 'NGN');
  });
}

class _ThrowingLoadRepo implements PreferenceRepository {
  @override
  Future<Preferences> getPreferences() async {
    throw const ApiException("Couldn't connect.");
  }

  @override
  Future<Preferences> updatePreferences(Map<String, dynamic> changes) {
    throw UnimplementedError();
  }
}
