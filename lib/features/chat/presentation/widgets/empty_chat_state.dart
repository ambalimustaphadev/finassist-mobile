import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/greeting_service.dart';
import '../../../../shared/widgets/list_action_card.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../data/prompt_suggestions.dart';

/// Shown in place of the message list for a genuinely new, empty
/// conversation: a short personalized greeting and a handful of tappable
/// starter prompts — pulled from a rotating pool so the screen doesn't
/// look identical (or anchored to one fixed demo scenario) every time.
/// Disappears the moment the first message is sent — see `ChatScreen`.
class EmptyChatState extends ConsumerStatefulWidget {
  const EmptyChatState({super.key, required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  @override
  ConsumerState<EmptyChatState> createState() => _EmptyChatStateState();
}

class _EmptyChatStateState extends ConsumerState<EmptyChatState> {
  late final List<PromptSuggestion> _suggestions = pickPromptSuggestions();

  @override
  Widget build(BuildContext context) {
    final firstName = ref.watch(
      currentUserIdentityProvider.select((identity) => identity.firstName),
    );
    final greetingWord = GreetingService.greetingFor(DateTime.now());
    final name = firstName.trim().isEmpty ? '' : ' $firstName';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text.rich(
          TextSpan(
            style: AppTypography.greeting(context),
            children: [
              TextSpan(text: '$greetingWord,\n'),
              TextSpan(text: '$name.'.trim()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'What would you like to know today?',
          style: AppTypography.body(context),
        ),
        const SizedBox(height: AppSpacing.xxl),
        for (final suggestion in _suggestions) ...[
          ListActionCard(
            icon: suggestion.icon,
            iconColor: suggestion.iconColor(context),
            title: suggestion.title,
            subtitle: suggestion.subtitle,
            onTap: () => widget.onSuggestionSelected(suggestion.title),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
