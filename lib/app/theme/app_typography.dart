import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography scale for FinAssist. Built on a bundled Inter
/// variable font to match the premium, high-hierarchy feel of the
/// reference design without depending on a network font fetch at runtime.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static TextStyle _base({
    required double fontSize,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// "Good morning, Mustapha" style large greeting.
  static TextStyle greeting = _base(
    fontSize: 26,
    weight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
  );

  /// Screen-level titles, e.g. "FinAssist AI".
  static TextStyle screenTitle = _base(
    fontSize: 17,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Section headings inside cards, e.g. "Spending overview".
  static TextStyle sectionHeading = _base(
    fontSize: 16,
    weight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  /// Card titles, e.g. "Statement".
  static TextStyle cardTitle = _base(fontSize: 15, weight: FontWeight.w600);

  static TextStyle body = _base(
    fontSize: 14,
    weight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle bodyMedium = _base(fontSize: 14, weight: FontWeight.w500);

  static TextStyle caption = _base(
    fontSize: 12,
    weight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  /// Large financial figures, e.g. "₦485,200".
  static TextStyle financialNumberLarge = _base(
    fontSize: 32,
    weight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static TextStyle financialNumberMedium = _base(
    fontSize: 19,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle financialNumberSmall = _base(
    fontSize: 14,
    weight: FontWeight.w700,
  );

  static TextStyle navLabel = _base(
    fontSize: 11,
    weight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextStyle chatMessage = _base(
    fontSize: 14.5,
    weight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle buttonLabel = _base(fontSize: 15, weight: FontWeight.w600);
}
