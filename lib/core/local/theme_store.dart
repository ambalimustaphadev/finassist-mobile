import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-scoped Appearance preference (System/Light/Dark). Same shape as
/// `OnboardingStore` — a thin wrapper over `FlutterSecureStorage` — kept
/// separate since this isn't an onboarding/auth-gate flag.
class ThemeStore {
  ThemeStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _themeModeKey = 'theme_mode_v1';

  Future<ThemeMode> readThemeMode() async {
    final raw = await _storage.read(key: _themeModeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    await _storage.write(key: _themeModeKey, value: mode.name);
  }
}

final themeStoreProvider = Provider<ThemeStore>((ref) => ThemeStore());
