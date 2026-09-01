import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The dark top section shared by Login and Register: heading, subtitle
/// and a small icon illustration. Paints full-bleed to the very top of the
/// screen (behind the status bar) with its own internal `SafeArea`,
/// matching the reference exactly.
///
/// Deliberately has no back button — Login and Register are the app's only
/// two entry points and already switch between each other via their own
/// "Register" / "Log in" links, so a back affordance here would be
/// redundant (and on Login, which is the root of the auth flow, would have
/// nothing to pop to).
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustrationIcon,
  });

  final String title;
  final String subtitle;
  final IconData illustrationIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.greeting),
                    const SizedBox(height: AppSpacing.sm),
                    Text(subtitle, style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Illustration(icon: illustrationIcon),
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStrong.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.accent, size: 32),
    );
  }
}
