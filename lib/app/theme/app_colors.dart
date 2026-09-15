import 'package:flutter/material.dart';

/// Centralized color system for FinAssist. All widgets should reference
/// these tokens instead of hardcoding color values.
abstract final class AppColors {
  // Backgrounds / surfaces — warm sage/off-white, per the chat-first
  // redesign's light visual language (dark is now confined to
  // [drawerBackground] and friends, below).
  static const Color background = Color(0xFFF3F6F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF7F9F7);
  static const Color surfaceHighlight = Color(0xFFEDF2ED);

  // Primary accent (mint/emerald green) — unchanged; already reads well on
  // both dark and light surfaces.
  static const Color accent = Color(0xFF55E39A);
  static const Color accentStrong = Color(0xFF2EDB87);
  static const Color accentSoft = Color(0xFF8AF5B8);

  // Text — deep navy-black on light surfaces.
  static const Color textPrimary = Color(0xFF131F1B);
  static const Color textSecondary = Color(0xFF5C6B64);
  static const Color textMuted = Color(0xFF8A9891);

  // Borders
  static const Color border = Color(0xFFE0E7E1);
  static Color borderSubtle = const Color(0xFFE0E7E1).withValues(alpha: 0.7);

  // Dark palette for the app's deliberately-dark surfaces: the
  // conversation-history side drawer (see ChatDrawer) and the pre-login
  // onboarding carousel (see the onboarding feature), both for contrast
  // against the otherwise-light app.
  static const Color drawerBackground = Color(0xFF0E1A15);
  static const Color drawerSurfaceSelected = Color(0xFF17271F);
  static const Color drawerText = Color(0xFFF5F7F5);
  static const Color drawerTextMuted = Color(0xFF8FA398);
  static const Color drawerBorder = Color(0xFF1F332A);
  static const Color drawerDanger = Color(0xFFE8836A);

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

  // Onboarding's light brand surface — a premium light register distinct
  // from the rest of the app (dark) and from auth's white-card-on-dark-
  // header treatment. Kept here (not a parallel palette) alongside the
  // other light-surface tokens above; [accent]/[accentStrong]/[accentDeep]
  // are reused directly for onboarding's emerald highlights and buttons.
  static const Color onboardingBackground = Color(0xFFFAFCFA);
  static const Color onboardingMintTint = Color(0xFFE6F5EC);
  static const Color onboardingHeading = Color(0xFF16213E);
  static const Color onboardingBodyMuted = Color(0xFF64748B);
}
