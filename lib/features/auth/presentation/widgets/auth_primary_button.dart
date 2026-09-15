import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The solid deep-green, pill-shaped CTA used for every primary auth action
/// ("Login", "Create account", ...) — shows a small inline spinner and
/// disables itself while [isLoading], and a trailing arrow glyph (matching
/// the reference's buttons) unless [showArrow] is turned off.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? AppColors.accentDeep
            : AppColors.accentDeep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppTypography.buttonLabel.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (showArrow) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
