import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../widgets/profile_section.dart';
import 'change_password_screen.dart';

/// Only shows security functionality that genuinely exists today. There's
/// no biometric unlock, app lock, or session management implemented in
/// this app, and the backend has no endpoint to list or revoke sessions —
/// so none of those appear here as switches that would do nothing.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Security', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'How your account is protected.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            const ProfileSectionLabel(label: 'Password'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.accentStrong,
                  title: 'Change password',
                  subtitle: 'Your account is protected by a password',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'FinAssist keeps your sign in secure with encrypted, '
              'token based authentication. Every request to your account '
              'is verified before it reaches your data.',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
