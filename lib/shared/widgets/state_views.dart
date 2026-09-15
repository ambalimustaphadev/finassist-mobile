import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Generic "nothing here yet" placeholder — reused across Activity, Home's
/// real-data sections and Tools instead of each screen inventing its own
/// empty-state layout.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Generic bounded loading placeholder — a centered spinner, not a
/// full-screen takeover, so it can sit inline within a scrollable section.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

/// Generic "something went wrong" state with an honest message and an
/// optional retry — never a silent blank space or a crash.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.message = "Something went wrong. Please try again.",
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textMuted,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center, style: AppTypography.body),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
