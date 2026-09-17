import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds FinAssist's Light and Dark [ThemeData]. Both share the same
/// typography, spacing, corner-radius system, icon system, navigation
/// structure and interaction patterns (see `app_typography.dart` /
/// `app_spacing.dart`) — only the [AppColorScheme] registered as a
/// [ThemeExtension] differs, and every widget reads colors through it via
/// `context.colors` rather than through `ColorScheme`/hardcoded values.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColorScheme.light());

  static ThemeData get dark => _build(Brightness.dark, AppColorScheme.dark());

  static ThemeData _build(Brightness brightness, AppColorScheme colors) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        primary: colors.accent,
        onPrimary: colors.textOnAccent,
        secondary: colors.accentStrong,
        onSecondary: colors.textOnAccent,
        error: colors.negative,
        onError: colors.textOnAccent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
        fontFamily: AppTypography.fontFamily,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: colors.border,
      iconTheme: IconThemeData(color: colors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.textMuted, fontFamily: AppTypography.fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.negative),
        ),
      ),
      extensions: [colors],
      // Android's Material 3 default (a soft fade+zoom) already reads as
      // premium, so it's left as-is; only iOS/macOS get overridden — their
      // default is Cupertino's edge-to-edge slide, which is the "one page
      // sliding over another like a book" effect this replaces with the
      // same subtle fade used everywhere else.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: _SubtleFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _SubtleFadePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// A short, subtle fade with the barest hint of upward motion — used in
/// place of the platform-default slide so pushed screens (Login, Register,
/// Personalization, detail screens, ...) feel like the same screen
/// smoothly resolving rather than a new page physically sliding/opening
/// over the old one.
class _SubtleFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SubtleFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
