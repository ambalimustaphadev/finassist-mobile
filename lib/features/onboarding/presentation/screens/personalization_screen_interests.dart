import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/personalization_controller.dart';
import '../widgets/personalization_scaffold.dart';
import '../widgets/personalization_selectors.dart';

/// Conversation topics — what the user wants to *talk about* with
/// FinAssist, never financial products/dashboard modules (no spending
/// tracker, budget tracker, portfolio, goals, etc. — those belong to a
/// different product concept).
const _interestOptions = [
  (
    label: 'General money questions',
    subtitle: 'Ask anything about money',
    icon: Icons.chat_bubble_outline_rounded,
  ),
  (
    label: 'Understanding documents',
    subtitle: 'Statements, bills, contracts…',
    icon: Icons.description_outlined,
  ),
  (
    label: 'Planning for life decisions',
    subtitle: 'Get clarity before big decisions',
    icon: Icons.explore_outlined,
  ),
  (
    label: 'Financial concepts',
    subtitle: 'Learn and understand easily',
    icon: Icons.lightbulb_outline_rounded,
  ),
  (
    label: 'Comparing options',
    subtitle: 'Get balanced, unbiased insights',
    icon: Icons.balance_rounded,
  ),
  (
    label: 'Tax-related questions',
    subtitle: 'Understand your tax questions',
    icon: Icons.percent_rounded,
  ),
  (label: 'Other', subtitle: 'Anything else', icon: Icons.more_horiz_rounded),
];

/// Page 4 — "Your interests". Multi-select conversation topics; the AI can
/// use these as conversational context later (e.g. prioritizing document
/// explanation or comparison-style answers). No backend field exists for
/// this yet — see `PersonalizationController`'s doc comment.
class PersonalizationInterestsScreen extends ConsumerWidget {
  const PersonalizationInterestsScreen({
    super.key,
    required this.onBack,
    required this.onSkip,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(
      personalizationControllerProvider.select((s) => s.interests),
    );
    final notifier = ref.read(personalizationControllerProvider.notifier);

    return PersonalizationScaffold(
      step: 4,
      eyebrow: 'YOUR INTERESTS',
      title: 'What would you like to\ntalk about with FinAssist?',
      subtitle:
          "Choose the topics you're most curious about. You can select "
          'multiple options.',
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: interests.isNotEmpty,
      body: Column(
        children: [
          for (final option in _interestOptions) ...[
            PersonalizationOptionRow(
              icon: option.icon,
              title: option.label,
              subtitle: option.subtitle,
              selected: interests.contains(option.label),
              onTap: () => notifier.toggleInterest(option.label),
              multiSelect: true,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
