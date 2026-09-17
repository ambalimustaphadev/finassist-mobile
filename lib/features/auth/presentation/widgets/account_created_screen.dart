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
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: context.colors.accentStrong,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  color: context.colors.textOnAccent,
                  size: 52,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text.rich(
                TextSpan(
                  style: AppTypography.greeting(context).copyWith(
                    fontSize: 28,
                    color: context.colors.textPrimary,
                  ),
                  children: [
                    const TextSpan(text: 'Account Created\n'),
                    TextSpan(
                      text: 'Successfully!',
                      style: TextStyle(color: context.colors.accentStrong),
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
                style: AppTypography.body(context).copyWith(
                  color: context.colors.textSecondary,
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
                  color: context.colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      '"A brighter financial future\nstarts with a single '
                      'step."',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(context).copyWith(
                        color: context.colors.accentStrong,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '— FinAssist',
                      style: AppTypography.caption(context).copyWith(
                        color: context.colors.accentStrong,
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
