import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// The three equal-width social sign-in shortcuts from the reference
/// (Google / Apple / email), shown on both Login and Register.
///
/// None of these are backed by a real provider today — the Flask backend
/// (`authroute/authroute.py`) only exposes `/api/register`, `/api/login`,
/// `/api/refresh` and `/api/me`, with no OAuth endpoint of any kind. Rather
/// than fake a working sign-in, every icon surfaces the same "coming soon"
/// cue the app already uses elsewhere (`GoogleSignInButton`'s previous,
/// single-button version of this), just extended evenly across all three
/// so none of them silently does nothing.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            onTap: () => _showComingSoon(context, 'Google'),
            child: const Text(
              'G',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SocialButton(
            label: 'Apple',
            onTap: () => _showComingSoon(context, 'Apple'),
            child: Icon(
              Icons.apple_rounded,
              size: 22,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SocialButton(
            label: 'Email',
            onTap: () => _showComingSoon(context, 'Email'),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.surfaceElevated,
          content: Text(
            '$provider sign-in is coming soon',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        ),
      );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with $label',
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.colors.border),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
