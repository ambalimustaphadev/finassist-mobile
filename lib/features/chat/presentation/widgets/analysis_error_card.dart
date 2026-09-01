import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Shown when statement analysis fails — calm, not alarming, with a clear
/// way forward. The normal mock flow never actually throws; this exists so
/// the app degrades gracefully if a future real backend does.
class AnalysisErrorCard extends StatelessWidget {
  const AnalysisErrorCard({
    super.key,
    required this.onTryAgain,
    required this.onChooseAnother,
  });

  final VoidCallback onTryAgain;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ErrorAction(label: 'Try again', onTap: onTryAgain),
        const SizedBox(width: AppSpacing.md),
        _ErrorAction(label: 'Choose another file', onTap: onChooseAnother),
      ],
    );
  }
}

class _ErrorAction extends StatelessWidget {
  const _ErrorAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}
