import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/personalization_controller.dart';
import '../widgets/personalization_scaffold.dart';
import '../widgets/personalization_selectors.dart';

const _experienceOptions = [
  (
    label: 'Beginner',
    subtitle: "I'm just getting started",
    icon: Icons.school_outlined,
  ),
  (
    label: 'Some knowledge',
    subtitle: 'I know the basics',
    icon: Icons.menu_book_outlined,
  ),
  (
    label: 'Moderate',
    subtitle: "I'm comfortable with most topics",
    icon: Icons.insights_rounded,
  ),
  (
    label: 'Advanced',
    subtitle: "I'm very knowledgeable",
    icon: Icons.star_rounded,
  ),
];

/// Page 3 — "Your experience". Single-select; how much financial
/// knowledge the user already has, not a financial-product risk profile —
/// the AI can use this to calibrate explanation depth (e.g. define
/// jargon for a beginner, skip it for an advanced user). No backend field
/// exists for this yet, so it lives only in `PersonalizationState` for the
/// current session — see `PersonalizationController`'s doc comment.
class PersonalizationExperienceScreen extends ConsumerWidget {
  const PersonalizationExperienceScreen({
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
    final experience = ref.watch(
      personalizationControllerProvider.select((s) => s.experience),
    );
    final notifier = ref.read(personalizationControllerProvider.notifier);

    return PersonalizationScaffold(
      step: 3,
      eyebrow: 'YOUR EXPERIENCE',
      title: 'How would you describe your\nexperience with personal finance?',
      subtitle: "This helps FinAssist tailor its explanations to your level.",
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: experience != null,
      body: Column(
        children: [
          for (final option in _experienceOptions) ...[
            PersonalizationOptionRow(
              icon: option.icon,
              title: option.label,
              subtitle: option.subtitle,
              selected: experience == option.label,
              onTap: () => notifier.setExperience(option.label),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
