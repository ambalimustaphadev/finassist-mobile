import 'package:flutter/material.dart';

/// Centralized color system for FinAssist. All widgets should reference
/// these tokens instead of hardcoding color values.
abstract final class AppColors {
  // Backgrounds / surfaces
  static const Color background = Color(0xFF050B12);
  static const Color surface = Color(0xFF0B141D);
  static const Color surfaceElevated = Color(0xFF101A24);
  static const Color surfaceHighlight = Color(0xFF121E29);

  // Primary accent (mint/emerald green)
  static const Color accent = Color(0xFF55E39A);
  static const Color accentStrong = Color(0xFF2EDB87);
  static const Color accentSoft = Color(0xFF8AF5B8);

  // Text
  static const Color textPrimary = Color(0xFFF5F7F8);
  static const Color textSecondary = Color(0xFF9AA7B3);
  static const Color textMuted = Color(0xFF66727E);

  // Borders
  static const Color border = Color(0xFF1C2A35);
  static Color borderSubtle = const Color(0xFF1C2A35).withValues(alpha: 0.6);

  // Category colors
  static const Color categoryFood = Color(0xFF2EDB87);
  static const Color categoryTransfers = Color(0xFF9B87F5);
  static const Color categoryShopping = Color(0xFFF2994A);
  static const Color categoryBills = Color(0xFF4F9EF0);
  static const Color categoryOthers = Color(0xFF7C8A97);

  // Status
  static const Color positive = accentStrong;
  static const Color negative = Color(0xFFE8654A);

  static const List<Color> ctaGradient = [Color(0xFF2EDB87), Color(0xFF55E9C7)];

  static const List<Color> donutGradient = [
    categoryFood,
    categoryTransfers,
    categoryShopping,
    categoryBills,
    categoryOthers,
  ];

  // Auth screens use the same dark header as the rest of the app, but the
  // reference design pairs it with a light form card — these are the only
  // light-surface tokens in the app, kept here (not a parallel palette) so
  // there's one source of truth.
  static const Color authSurface = Color(0xFFFFFFFF);
  static const Color authInputFill = Color(0xFFF4F5F7);
  static const Color authInputBorder = Color(0xFFE3E6EA);
  static const Color authTextPrimary = Color(0xFF15181B);
  static const Color authTextMuted = Color(0xFF8A94A0);

  /// A deeper shade of the same accent green family, used for solid CTA
  /// buttons on the light auth card where the bright mint [accent] would
  /// read too neon and lack contrast against white.
  static const Color accentDeep = Color(0xFF1B4332);
}
