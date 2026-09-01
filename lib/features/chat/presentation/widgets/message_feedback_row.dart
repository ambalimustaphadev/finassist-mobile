import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/chat_message.dart';
import '../providers/chat_controller.dart';

const _notHelpfulReasons = [
  'Too generic',
  'Not relevant',
  'Incorrect',
  'Hard to understand',
];

/// Lightweight "Was this helpful?" rating for a substantive AI answer.
/// Selecting "not helpful" reveals a short list of reasons.
class MessageFeedbackRow extends ConsumerWidget {
  const MessageFeedbackRow({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatControllerProvider.notifier);

    if (message.helpful == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Was this helpful?', style: AppTypography.caption),
          const SizedBox(width: AppSpacing.sm),
          _FeedbackIconButton(
            icon: Icons.thumb_up_outlined,
            semanticLabel: 'Mark helpful',
            onTap: () => notifier.setMessageFeedback(message.id, helpful: true),
          ),
          const SizedBox(width: 4),
          _FeedbackIconButton(
            icon: Icons.thumb_down_outlined,
            semanticLabel: 'Mark not helpful',
            onTap: () =>
                notifier.setMessageFeedback(message.id, helpful: false),
          ),
        ],
      );
    }

    if (message.helpful == true) {
      return Text('Thanks for the feedback', style: AppTypography.caption);
    }

    // helpful == false: offer reasons unless one is already picked.
    if (message.notHelpfulReason != null) {
      return Text('Thanks — noted.', style: AppTypography.caption);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('What was missing?', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final reason in _notHelpfulReasons)
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: () => notifier.setMessageFeedback(
                    message.id,
                    helpful: false,
                    reason: reason,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(reason, style: AppTypography.caption),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeedbackIconButton extends StatelessWidget {
  const _FeedbackIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
