import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/theme/theme_mode_controller.dart';
import 'package:finassist/core/local/theme_store.dart';

class _FakeThemeStore extends ThemeStore {
  _FakeThemeStore({ThemeMode? persisted}) : _persisted = persisted;

  ThemeMode? _persisted;
  int writeCount = 0;

  @override
  Future<ThemeMode> readThemeMode() async => _persisted ?? ThemeMode.system;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    writeCount++;
    _persisted = mode;
  }
}

void main() {
  test('defaults to system before the persisted value loads', () {
    final controller = ThemeModeController(_FakeThemeStore());
    expect(controller.state, ThemeMode.system);
  });

  test('adopts the persisted value once loaded', () async {
    final controller = ThemeModeController(
      _FakeThemeStore(persisted: ThemeMode.dark),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state, ThemeMode.dark);
  });

  test('setThemeMode updates state immediately, independent of the write',
      () async {
    final store = _FakeThemeStore();
    final controller = ThemeModeController(store);
    await Future<void>.delayed(Duration.zero);

    final future = controller.setThemeMode(ThemeMode.light);
    expect(controller.state, ThemeMode.light);

    await future;
    expect(store.writeCount, 1);
  });

  test('setThemeMode persists the choice for the next launch', () async {
    final store = _FakeThemeStore();
    final controller = ThemeModeController(store);
    await Future<void>.delayed(Duration.zero);

    await controller.setThemeMode(ThemeMode.dark);

    final restored = ThemeModeController(store);
    await Future<void>.delayed(Duration.zero);
    expect(restored.state, ThemeMode.dark);
  });
}
