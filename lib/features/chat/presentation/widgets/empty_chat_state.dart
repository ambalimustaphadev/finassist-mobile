import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/greeting_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/models/quick_action.dart';
import 'quick_action_chip.dart';

const List<QuickAction> _suggestions = [
  QuickAction(
    label: 'How much did I spend?',
    icon: Icons.query_stats_rounded,
    prompt: 'How much did I spend this month?',
  ),
  QuickAction(
    label: 'Create a budget',
    icon: Icons.calculate_rounded,
    prompt: 'Can you help me create a budget?',
  ),
  QuickAction(
    label: 'Analyze my spending',
    icon: Icons.pie_chart_rounded,
    prompt: 'Analyze my spending this month.',
  ),
];

/// Shown in place of the message list for a genuinely new, empty
/// conversation: a short, personalized greeting and a few tappable
/// suggestions — never a long canned paragraph.
class EmptyChatState extends ConsumerWidget {
  const EmptyChatState({super.key, required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(
      authControllerProvider.select((state) => state.user?.firstName),
    );
    final greetingWord = GreetingService.greetingFor(DateTime.now());
    final name = (firstName == null || firstName.trim().isEmpty)
        ? ''
        : ', $firstName';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greetingWord$name.', style: AppTypography.greeting),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'What can I help you with?',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final suggestion in _suggestions)
                  QuickActionChip(
                    action: suggestion,
                    onTap: () => onSuggestionSelected(suggestion.prompt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
