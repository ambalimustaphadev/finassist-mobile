import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// Shown for Profile rows that have real navigation but no backend support
/// yet (Personal information, Change password, Security) — honest about
/// what isn't available rather than pretending the action succeeded.
class UnavailableFeatureScreen extends StatelessWidget {
  const UnavailableFeatureScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(title, style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconBadge(
                  icon: icon,
                  color: AppColors.textMuted,
                  size: 56,
                  iconSize: 26,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  "This isn't available yet",
                  style: AppTypography.sectionHeading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
