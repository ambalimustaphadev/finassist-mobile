import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/personalization_controller.dart';
import '../widgets/finassist_robot_avatar.dart';
import '../widgets/personalization_header.dart';
import '../widgets/personalization_scaffold.dart';

/// Page 6 — the completion page. No question, no dashboard, no financial
/// statistics — just a summary of what was actually answered (never
/// hardcoded) and the final "Continue to FinAssist" action, which is the
/// one thing on this page that actually saves anything.
class PersonalizationCompleteScreen extends ConsumerWidget {
  const PersonalizationCompleteScreen({
    super.key,
    required this.onBack,
    required this.onEdit,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personalizationControllerProvider);

    final summary = <(IconData, String)>[
      if (state.situation != null) (Icons.badge_outlined, state.situation!),
      if (state.experience != null) (Icons.school_outlined, state.experience!),
      if (state.interests.isNotEmpty)
        (Icons.chat_bubble_outline_rounded, state.interests.join(', ')),
      if (state.responseStyle != null)
        (Icons.article_outlined, state.responseStyle!),
      (
        Icons.lightbulb_outline_rounded,
        'Proactive suggestions ${state.proactiveSuggestions ? 'enabled' : 'disabled'}',
      ),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            PersonalizationHeader(step: 6, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const FinAssistRobotAvatar(size: 96, celebrating: true),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      "You're all set!",
                      textAlign: TextAlign.center,
                      style: AppTypography.greeting(context).copyWith(
                        fontSize: 26,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'FinAssist is now personalized\nto give you more '
                      'relevant,\nhelpful and practical answers.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(context).copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (summary.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Your preferences',
                                    style: AppTypography.bodyMedium(context)
                                        .copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                TextButton(
                                  key: const Key('personalization-edit'),
                                  onPressed: onEdit,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: AppTypography.bodyMedium(context)
                                        .copyWith(
                                          color: context.colors.accentStrong,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (final row in summary) ...[
                              _SummaryRow(icon: row.$1, label: row.$2),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: PersonalizationContinueButton(
                step: 6,
                label: 'Continue to FinAssist',
                isSaving: state.isSaving,
                onTap: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.colors.accentStrong),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(color: context.colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
