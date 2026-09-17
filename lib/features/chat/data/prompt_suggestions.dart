import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// A starter prompt shown on the empty-chat landing state.
class PromptSuggestion {
  const PromptSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Resolves the icon's tint against the active theme — colors can't be
  /// baked in at pool-construction time since `context.colors` needs a
  /// [BuildContext] (see `AppColorsX` in `app_colors.dart`).
  final Color Function(BuildContext context) iconColor;
}

/// A pool of generic, reusable financial prompts — deliberately not
/// anchored to one specific scenario (e.g. "Can I afford a new laptop?")
/// so the landing screen never feels like a fixed demo script.
final List<PromptSuggestion> _pool = [
  PromptSuggestion(
    title: 'Help me create a savings plan',
    subtitle: 'Set and achieve your goals',
    icon: Icons.savings_rounded,
    iconColor: (context) => context.colors.accentStrong,
  ),
  PromptSuggestion(
    title: 'Analyze my bank statement',
    subtitle: 'Upload a statement and get insights',
    icon: Icons.description_outlined,
    iconColor: (context) => context.colors.categoryBills,
  ),
  PromptSuggestion(
    title: 'Why am I overspending?',
    subtitle: 'Find out and fix it',
    icon: Icons.trending_down_rounded,
    iconColor: (context) => context.colors.negative,
  ),
  PromptSuggestion(
    title: 'Help me create a budget',
    subtitle: 'Build a realistic spending plan',
    icon: Icons.calculate_rounded,
    iconColor: (context) => context.colors.categoryTransfers,
  ),
  PromptSuggestion(
    title: 'How can I save more money?',
    subtitle: 'Small changes, real impact',
    icon: Icons.lightbulb_outline_rounded,
    iconColor: (context) => context.colors.categoryShopping,
  ),
  PromptSuggestion(
    title: 'Help me plan for a major purchase',
    subtitle: 'Get a clear, realistic answer',
    icon: Icons.chat_bubble_outline_rounded,
    iconColor: (context) => context.colors.accent,
  ),
  PromptSuggestion(
    title: 'What should I do with my extra income?',
    subtitle: 'Make it work harder for you',
    icon: Icons.trending_up_rounded,
    iconColor: (context) => context.colors.categoryFood,
  ),
  PromptSuggestion(
    title: 'Explain a recent expense',
    subtitle: 'Understand where the money went',
    icon: Icons.receipt_long_rounded,
    iconColor: (context) => context.colors.categoryOthers,
  ),
];

/// Picks [count] suggestions from the pool, shuffled so the landing
/// screen doesn't show the exact same four every time.
List<PromptSuggestion> pickPromptSuggestions({int count = 4}) {
  final shuffled = List<PromptSuggestion>.of(_pool)..shuffle(Random());
  return shuffled.take(count).toList();
}
