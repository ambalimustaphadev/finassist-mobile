import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The divider between the primary CTA and the social buttons row, e.g.
/// "Or continue with" on Login, "Or sign up with" on Register.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.authInputBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: AppTypography.caption),
        ),
        const Expanded(child: Divider(color: AppColors.authInputBorder)),
      ],
    );
  }
}
