import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/personalization_controller.dart';
import '../widgets/personalization_scaffold.dart';
import '../widgets/personalization_selectors.dart';

const _responseStyleOptions = [
  (
    label: 'Simple and clear',
    subtitle: 'Easy to understand, no jargon',
    icon: Icons.chat_bubble_outline_rounded,
  ),
  (
    label: 'Balanced',
    subtitle: 'A mix of simplicity and detail',
    icon: Icons.balance_rounded,
  ),
  (
    label: 'Detailed',
    subtitle: 'In-depth explanations with examples',
    icon: Icons.article_outlined,
  ),
];

/// Page 5 — "Response style", plus a compact "Proactive suggestions"
/// communication preference below the question. Response style directly
/// shapes how the AI should phrase answers later; proactive suggestions is
/// simply whether FinAssist may occasionally volunteer a tip unprompted —
/// neither turns this into a notification-heavy product.
class PersonalizationResponseStyleScreen extends ConsumerWidget {
  const PersonalizationResponseStyleScreen({
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
    final state = ref.watch(personalizationControllerProvider);
    final notifier = ref.read(personalizationControllerProvider.notifier);

    return PersonalizationScaffold(
      step: 5,
      eyebrow: 'RESPONSE STYLE',
      title: 'How would you like\nFinAssist to respond?',
      subtitle:
          'Choose a style that feels right for you. You can change this '
          'anytime.',
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: state.responseStyle != null,
      body: Column(
        children: [
          for (final option in _responseStyleOptions) ...[
            PersonalizationOptionRow(
              icon: option.icon,
              title: option.label,
              subtitle: option.subtitle,
              selected: state.responseStyle == option.label,
              onTap: () => notifier.setResponseStyle(option.label),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          PersonalizationToggleRow(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Proactive suggestions',
            subtitle:
                'Allow FinAssist to occasionally share helpful tips, '
                'insights and things to consider.',
            value: state.proactiveSuggestions,
            onChanged: notifier.setProactiveSuggestions,
          ),
        ],
      ),
    );
  }
}
