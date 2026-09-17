import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../widgets/finassist_robot_avatar.dart';
import '../widgets/personalization_scaffold.dart';

const _benefits = [
  (
    icon: Icons.tune_rounded,
    title: 'Advice tailored to you',
    subtitle: 'Answers that fit your situation',
  ),
  (
    icon: Icons.insights_rounded,
    title: 'More relevant insights',
    subtitle: 'Based on your interests',
  ),
  (
    icon: Icons.chat_bubble_outline_rounded,
    title: 'A better chat experience',
    subtitle: 'The more you share, the more helpful I can be',
  ),
];

/// Page 1 — the personalization flow's introduction. No question here;
/// just sets up why the next few pages exist. Nothing precedes this page
/// (it's what `AuthGate` shows directly once a fresh account exists), so
/// it has no back arrow.
class PersonalizationIntroScreen extends StatelessWidget {
  const PersonalizationIntroScreen({
    super.key,
    required this.onSkip,
    required this.onContinue,
  });

  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return PersonalizationScaffold(
      step: 1,
      title: "Let's personalize\nFinAssist for you.",
      subtitle:
          'Tell us a bit about yourself so FinAssist can give you more '
          'relevant and helpful answers.',
      onSkip: onSkip,
      onContinue: onContinue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RobotWithSpeechBubble(),
          const SizedBox(height: AppSpacing.xl),
          for (final benefit in _benefits) ...[
            _BenefitRow(
              icon: benefit.icon,
              title: benefit.title,
              subtitle: benefit.subtitle,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _RobotWithSpeechBubble extends StatelessWidget {
  const _RobotWithSpeechBubble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            bottom: 0,
            child: FinAssistRobotAvatar(size: 88),
          ),
          Positioned(
            left: 76,
            top: 4,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colors.border),
              ),
              child: Text(
                'Different people. Different questions. A better FinAssist.',
                style: AppTypography.caption(context).copyWith(
                  color: context.colors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.colors.accentSoft,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: context.colors.accentStrong, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium(context).copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.caption(
                  context,
                ).copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
