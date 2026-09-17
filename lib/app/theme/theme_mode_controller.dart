import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/local/theme_store.dart';

/// The single source of truth for FinAssist's Appearance setting. Seeded to
/// [ThemeMode.system] and updated once the persisted choice loads — mirrors
/// `PreferencesController`'s load-in-constructor pattern. `MaterialApp`
/// watches this directly (see `app.dart`), so every change applies
/// app-wide immediately with no restart.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._store) : super(ThemeMode.system) {
    _load();
  }

  final ThemeStore _store;

  Future<void> _load() async {
    final mode = await _store.readThemeMode();
    if (mounted) state = mode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _store.writeThemeMode(mode);
  }
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
      return ThemeModeController(ref.watch(themeStoreProvider));
    });
