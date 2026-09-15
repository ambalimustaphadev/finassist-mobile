import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../providers/personalization_controller.dart';
import '../widgets/personalization_scaffold.dart';
import '../widgets/personalization_selectors.dart';

const _situationOptions = [
  (
    label: 'Student',
    subtitle: 'Currently studying',
    icon: Icons.school_outlined,
  ),
  (
    label: 'Employed',
    subtitle: 'I have a job',
    icon: Icons.work_outline_rounded,
  ),
  (
    label: 'Self-employed',
    subtitle: 'I work for myself',
    icon: Icons.badge_outlined,
  ),
  (
    label: 'Business owner',
    subtitle: 'I own a business',
    icon: Icons.storefront_outlined,
  ),
  (
    label: 'Other',
    subtitle: 'Prefer not to say',
    icon: Icons.more_horiz_rounded,
  ),
];

/// Page 2 — "About you". Single-select; the only personalization question
/// with a real backend field (`employment_status`) to persist to — see
/// `PersonalizationController`.
class PersonalizationSituationScreen extends ConsumerWidget {
  const PersonalizationSituationScreen({
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
    final situation = ref.watch(
      personalizationControllerProvider.select((s) => s.situation),
    );
    final notifier = ref.read(personalizationControllerProvider.notifier);

    return PersonalizationScaffold(
      step: 2,
      eyebrow: 'ABOUT YOU',
      title: 'What best describes\nyou right now?',
      subtitle:
          'This helps FinAssist understand your background and give you '
          'more relevant answers.',
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
      continueEnabled: situation != null,
      body: Column(
        children: [
          for (final option in _situationOptions) ...[
            PersonalizationOptionRow(
              icon: option.icon,
              title: option.label,
              subtitle: option.subtitle,
              selected: situation == option.label,
              onTap: () => notifier.setSituation(option.label),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
