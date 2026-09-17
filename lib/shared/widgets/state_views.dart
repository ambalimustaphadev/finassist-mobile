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
          Icon(icon, color: context.colors.textMuted, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(context),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                context,
              ).copyWith(color: context.colors.textMuted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(color: context.colors.accent),
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
      child: Center(
        child: CircularProgressIndicator(
          color: context.colors.accent,
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
          Icon(
            Icons.error_outline_rounded,
            color: context.colors.textMuted,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(context),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(color: context.colors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
