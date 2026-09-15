import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the single light [ThemeData] used across FinAssist's main app
/// (Chat/Quick/Tools/Profile). The conversation-history drawer is the one
/// deliberately dark surface left, styled directly with the `drawer*`
/// tokens rather than through a second app-wide theme.
abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.background,
        primary: AppColors.accent,
        secondary: AppColors.accentStrong,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: AppTypography.body.fontFamily,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
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
