import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The full-width, filled pill CTA reused across the Subscription Tracker
/// flow (Continue, Save subscription, Save changes, Add subscription) —
/// same shape as `AuthPrimaryButton`, but with a plain label and no forced
/// trailing arrow.
class SubscriptionPrimaryButton extends StatelessWidget {
  const SubscriptionPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? context.colors.accent
            : context.colors.accent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: context.colors.textOnAccent,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTypography.buttonLabel(context).copyWith(
                        color: context.colors.textOnAccent,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
