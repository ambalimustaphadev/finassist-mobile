import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import 'auth_primary_button.dart';

/// Pushed by Register only after the real registration API call actually
/// succeeds — never shown unconditionally. Replaces the previous bottom
/// sheet with a full-screen success moment matching the reference, while
/// keeping the exact same call shape (`onContinue`) so the caller's flow
/// (pop back to Login) is unchanged.
Future<void> showAccountCreatedScreen(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AccountCreatedScreen(onContinue: onContinue),
    ),
  );
}

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.accentDeep,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text.rich(
                TextSpan(
                  style: AppTypography.greeting.copyWith(
                    fontSize: 28,
                    color: AppColors.onboardingHeading,
                  ),
                  children: const [
                    TextSpan(text: 'Account Created\n'),
                    TextSpan(
                      text: 'Successfully!',
                      style: TextStyle(color: AppColors.accentDeep),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Your account has been created and you're all set to start "
                'your journey with FinAssist.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.onboardingBodyMuted,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              AuthPrimaryButton(
                label: 'Continue',
                onPressed: () {
                  Navigator.of(context).pop();
                  onContinue();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.onboardingMintTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '"A brighter financial future\nstarts with a single '
                      'step."',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.accentDeep,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '— FinAssist',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
