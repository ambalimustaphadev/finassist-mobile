import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// The selected-vs-unselected card treatment every option row shares: an
/// emerald border + pale mint surface when selected, a plain white/light
/// card with a gray border otherwise.
BoxDecoration _selectionDecoration(bool selected) {
  return BoxDecoration(
    color: selected ? AppColors.onboardingMintTint : AppColors.authSurface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: selected ? AppColors.accentDeep : AppColors.authInputBorder,
      width: selected ? 1.5 : 1,
    ),
  );
}

/// A full-width option row used by every personalization question: an icon
/// badge, a title + short subtitle, and a trailing selection indicator —
/// a filled circle (radio) for single-select questions, a filled
/// checkmark square (checkbox) for multi-select ones, matching the
/// reference exactly rather than the default `RadioListTile`/
/// `CheckboxListTile` styling.
class PersonalizationOptionRow extends StatelessWidget {
  const PersonalizationOptionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.multiSelect = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// `true` renders a checkbox-style square indicator (Page 4's "select
  /// multiple"); `false` (the default) renders a radio-style circle.
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: _selectionDecoration(selected),
          child: Row(
            children: [
              IconBadge(
                icon: icon,
                color: AppColors.accentDeep,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.authTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.onboardingBodyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SelectionIndicator(selected: selected, multiSelect: multiSelect),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.selected,
    required this.multiSelect,
  });

  final bool selected;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final shape = multiSelect ? BoxShape.rectangle : BoxShape.circle;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: multiSelect ? BorderRadius.circular(6) : null,
        color: selected ? AppColors.accentDeep : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.accentDeep : AppColors.authInputBorder,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// A compact preference row (Page 5's "Proactive suggestions") — an icon
/// badge, title + subtitle, and a trailing `Switch`, matching the toggle
/// styling already used on Profile's notification preferences.
class PersonalizationToggleRow extends StatelessWidget {
  const PersonalizationToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.authSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.authInputBorder),
      ),
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            color: AppColors.accentDeep,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.authTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onboardingBodyMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
