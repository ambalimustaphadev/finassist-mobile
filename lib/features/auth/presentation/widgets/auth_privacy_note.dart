import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The soft green reassurance strip on the register screen. Kept honest —
/// no exaggerated security claims, just a plain statement.
class AuthPrivacyNote extends StatelessWidget {
  const AuthPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 18,
            color: AppColors.accentDeep,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Your data is safe with us. We never share your information with anyone.',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentDeep,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
