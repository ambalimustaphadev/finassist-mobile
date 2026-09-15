import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Contextual "you could also ask" chips shown beneath a substantive
/// assistant answer. Tapping one behaves exactly like typing and sending
/// that prompt.
class FollowUpSuggestions extends StatelessWidget {
  const FollowUpSuggestions({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final suggestion in suggestions)
          Material(
            color: AppColors.onboardingMintTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: () => onSelect(suggestion),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  suggestion,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
