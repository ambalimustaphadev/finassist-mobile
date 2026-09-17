import 'package:flutter/material.dart';

/// FinAssist's centralized, theme-aware color tokens. Every widget reads
/// these via `context.colors.xxx` (see [AppColorsX] below) instead of
/// hardcoding a [Color] — the same token resolves to a different [Color]
/// depending on the active [ThemeMode], which is what makes light/dark mode
/// work app-wide without per-screen branching.
///
/// Registered on [ThemeData] as a [ThemeExtension] (see `app_theme.dart`),
/// so it participates in Flutter's normal theme change/animation machinery.
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHighlight,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.textOnAccent,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.info,
    required this.categoryFood,
    required this.categoryTransfers,
    required this.categoryShopping,
    required this.categoryBills,
    required this.categoryOthers,
    required this.ctaGradient,
    required this.donutGradient,
  });

  /// Screen/scaffold background — the app's "floor".
  final Color background;

  /// Base card/sheet/composer surface, one step up from [background].
  final Color surface;

  /// A further step up from [surface] — used for nested surfaces that need
  /// to read as "above" a card (e.g. a summary tile inside a screen body).
  final Color surfaceElevated;

  /// Pressed/selected/tinted surface — e.g. the user's own chat bubble, a
  /// selected drawer row, an active toggle's fill.
  final Color surfaceHighlight;

  final Color border;
  final Color borderSubtle;

  /// Highest-contrast text — headings, primary body copy, values.
  final Color textPrimary;

  /// Secondary text — supporting copy, row subtitles.
  final Color textSecondary;

  /// Lowest-emphasis text still meant to be read — captions, nav labels,
  /// metadata. Never used for anything the user must not miss.
  final Color textMuted;

  /// FinAssist's brand emerald — CTAs, active/interactive accents.
  final Color accent;

  /// Pressed/hover state of [accent].
  final Color accentStrong;

  /// A soft tint of [accent] for pill backgrounds/selected chips.
  final Color accentSoft;

  /// Text/icon color drawn on top of a solid [accent] fill.
  final Color textOnAccent;

  final Color positive;
  final Color negative;
  final Color warning;
  final Color info;

  final Color categoryFood;
  final Color categoryTransfers;
  final Color categoryShopping;
  final Color categoryBills;
  final Color categoryOthers;

  final List<Color> ctaGradient;
  final List<Color> donutGradient;

  static const _lightAccent = Color(0xFF35D39A);
  // A deeper, contrast-safe emerald — not the spec's literal "pressed"
  // value (#29B982), which is still too light for text/icon use directly
  // on a light surface (~4.3:1 against white; #12805A clears ~4.9:1). Used
  // wherever the accent color is drawn as small text/an icon glyph rather
  // than as a large filled surface (where accent + textOnAccent is used
  // instead) — e.g. links, checkmarks, status-pill text.
  static const _lightAccentStrong = Color(0xFF12805A);
  static const _darkAccent = Color(0xFF35D39A);
  static const _darkAccentStrong = Color(0xFF29B982);

  factory AppColorScheme.light() {
    return const AppColorScheme(
      background: Color(0xFFF7FAF8),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF2F7F4),
      surfaceHighlight: Color(0xFFE6F5EC),
      border: Color(0xFFE1EBE6),
      borderSubtle: Color(0xFFEDF3EF),
      textPrimary: Color(0xFF10231E),
      textSecondary: Color(0xFF526761),
      textMuted: Color(0xFF7B8C86),
      accent: _lightAccent,
      accentStrong: _lightAccentStrong,
      accentSoft: Color(0xFFDBF4E8),
      textOnAccent: Color(0xFF06110D),
      positive: _lightAccentStrong,
      negative: Color(0xFFE45D5D),
      warning: Color(0xFFC99635),
      info: Color(0xFF4F8FD9),
      categoryFood: Color(0xFF2EDB87),
      categoryTransfers: Color(0xFF9B87F5),
      categoryShopping: Color(0xFFF2994A),
      categoryBills: Color(0xFF4F9EF0),
      categoryOthers: Color(0xFF7C8A97),
      ctaGradient: [Color(0xFF2EDB87), Color(0xFF55E9C7)],
      donutGradient: [
        Color(0xFF2EDB87),
        Color(0xFF9B87F5),
        Color(0xFFF2994A),
        Color(0xFF4F9EF0),
        Color(0xFF7C8A97),
      ],
    );
  }

  factory AppColorScheme.dark() {
    return const AppColorScheme(
      background: Color(0xFF08110F),
      surface: Color(0xFF0D1916),
      surfaceElevated: Color(0xFF12221E),
      surfaceHighlight: Color(0xFF172A25),
      border: Color(0xFF1C302B),
      borderSubtle: Color(0xFF16241F),
      textPrimary: Color(0xFFF4F8F6),
      textSecondary: Color(0xFFA7B7B1),
      textMuted: Color(0xFF71847D),
      accent: _darkAccent,
      accentStrong: _darkAccentStrong,
      accentSoft: Color(0xFF1B3229),
      textOnAccent: Color(0xFF06110D),
      positive: _darkAccentStrong,
      negative: Color(0xFFFF6B6B),
      warning: Color(0xFFF2C66D),
      info: Color(0xFF6DB6FF),
      categoryFood: Color(0xFF2EDB87),
      categoryTransfers: Color(0xFFAD9AF7),
      categoryShopping: Color(0xFFF5AC69),
      categoryBills: Color(0xFF6DB6FF),
      categoryOthers: Color(0xFF93A0A9),
      ctaGradient: [Color(0xFF2EDB87), Color(0xFF55E9C7)],
      donutGradient: [
        Color(0xFF2EDB87),
        Color(0xFFAD9AF7),
        Color(0xFFF5AC69),
        Color(0xFF6DB6FF),
        Color(0xFF93A0A9),
      ],
    );
  }

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHighlight,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentStrong,
    Color? accentSoft,
    Color? textOnAccent,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? info,
    Color? categoryFood,
    Color? categoryTransfers,
    Color? categoryShopping,
    Color? categoryBills,
    Color? categoryOthers,
    List<Color>? ctaGradient,
    List<Color>? donutGradient,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSoft: accentSoft ?? this.accentSoft,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      categoryFood: categoryFood ?? this.categoryFood,
      categoryTransfers: categoryTransfers ?? this.categoryTransfers,
      categoryShopping: categoryShopping ?? this.categoryShopping,
      categoryBills: categoryBills ?? this.categoryBills,
      categoryOthers: categoryOthers ?? this.categoryOthers,
      ctaGradient: ctaGradient ?? this.ctaGradient,
      donutGradient: donutGradient ?? this.donutGradient,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> cl(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], i < b.length ? b[i] : a[i]),
    ];
    return AppColorScheme(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceHighlight: c(surfaceHighlight, other.surfaceHighlight),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      accentStrong: c(accentStrong, other.accentStrong),
      accentSoft: c(accentSoft, other.accentSoft),
      textOnAccent: c(textOnAccent, other.textOnAccent),
      positive: c(positive, other.positive),
      negative: c(negative, other.negative),
      warning: c(warning, other.warning),
      info: c(info, other.info),
      categoryFood: c(categoryFood, other.categoryFood),
      categoryTransfers: c(categoryTransfers, other.categoryTransfers),
      categoryShopping: c(categoryShopping, other.categoryShopping),
      categoryBills: c(categoryBills, other.categoryBills),
      categoryOthers: c(categoryOthers, other.categoryOthers),
      ctaGradient: cl(ctaGradient, other.ctaGradient),
      donutGradient: cl(donutGradient, other.donutGradient),
    );
  }
}

/// The single entry point for reading theme-aware colors: `context.colors.textPrimary`.
extension AppColorsX on BuildContext {
  AppColorScheme get colors => Theme.of(this).extension<AppColorScheme>()!;
}
