import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/coming_soon_snack_bar.dart';
import '../../../../shared/widgets/confirm_action_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_finance_controller.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_section.dart';
import '../widgets/unavailable_feature_screen.dart';
import 'documents_screen.dart';
import 'financial_data_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(profileFinanceControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Profile', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            const ProfileHeaderCard(),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Account'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.categoryBills,
                  title: 'Personal information',
                  subtitle: 'Update your name, email and more',
                  onTap: () => _openUnavailable(
                    context,
                    title: 'Personal information',
                    icon: Icons.person_outline_rounded,
                    message:
                        "Editing your name, email and other details isn't available yet. "
                        'This will let you update your personal information once '
                        'FinAssist adds support for it.',
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.accentStrong,
                  title: 'Change password',
                  subtitle: 'Update your password',
                  onTap: () => _openUnavailable(
                    context,
                    title: 'Change password',
                    icon: Icons.lock_outline_rounded,
                    message:
                        "Changing your password from the app isn't available yet.",
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.categoryTransfers,
                  title: 'Security',
                  subtitle: 'Manage your account security',
                  onTap: () => _openUnavailable(
                    context,
                    title: 'Security',
                    icon: Icons.shield_outlined,
                    message: "Account security settings aren't available yet.",
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Your Finances'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.categoryBills,
                  title: 'Documents',
                  subtitle: 'View and manage your uploaded financial documents',
                  trailing: financeState.statements.isEmpty
                      ? null
                      : ProfileCountBadge(
                          count: financeState.statements.length,
                        ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.pie_chart_outline_rounded,
                  iconColor: AppColors.accentStrong,
                  title: 'Financial data',
                  subtitle: 'View your extracted financial data',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FinancialDataScreen(),
                    ),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.negative,
                  title: 'Delete financial data',
                  subtitle: 'Delete all your financial data from FinAssist',
                  isDestructive: true,
                  onTap: () => _handleDeleteFinancialData(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Preferences'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.notifications_none_rounded,
                  iconColor: AppColors.categoryShopping,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () => showComingSoonSnackBar(context, 'Notifications'),
                ),
                ProfileMenuRow(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.categoryBills,
                  title: 'Language',
                  subtitle: 'Choose your preferred language',
                  onTap: () => showComingSoonSnackBar(context, 'Language'),
                ),
                ProfileMenuRow(
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.accentStrong,
                  title: 'Currency',
                  subtitle: 'Choose your preferred currency',
                  onTap: () => showComingSoonSnackBar(context, 'Currency'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Privacy & Security'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.categoryBills,
                  title: 'Privacy',
                  subtitle: 'Manage your privacy settings',
                  onTap: () =>
                      showComingSoonSnackBar(context, 'Privacy settings'),
                ),
                ProfileMenuRow(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.accentStrong,
                  title: 'Data & AI controls',
                  subtitle: 'Manage how your data is used by FinAssist',
                  onTap: () =>
                      showComingSoonSnackBar(context, 'Data & AI controls'),
                ),
                ProfileMenuRow(
                  icon: Icons.vpn_key_outlined,
                  iconColor: AppColors.categoryTransfers,
                  title: 'Manage app permissions',
                  subtitle: 'Manage FinAssist app permissions',
                  onTap: openAppSettings,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Support'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.categoryBills,
                  title: 'Help & FAQ',
                  subtitle: 'Get help and find answers',
                  onTap: () => showComingSoonSnackBar(context, 'Help & FAQ'),
                ),
                ProfileMenuRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.accentStrong,
                  title: 'Contact support',
                  subtitle: 'Reach out to our support team',
                  onTap: () =>
                      showComingSoonSnackBar(context, 'Contact support'),
                ),
                ProfileMenuRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.categoryTransfers,
                  title: 'About FinAssist',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const _LogoutButton(),
          ],
        ),
      ),
    );
  }

  void _openUnavailable(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String message,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnavailableFeatureScreen(
          title: title,
          icon: icon,
          message: message,
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('About FinAssist', style: AppTypography.sectionHeading),
        content: Text(
          'Version 1.0.0\n\nYour financial assistant.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteFinancialData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Delete financial data?',
      message:
          'All financial data extracted from your uploaded statements will be '
          "permanently removed from FinAssist. This won't delete your bank account.",
      confirmLabel: 'Delete data',
      isDestructive: true,
    );
    if (!confirmed) return;

    final success = await ref
        .read(profileFinanceControllerProvider.notifier)
        .deleteFinancialData();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            success
                ? 'Your financial data has been deleted.'
                : "Couldn't delete your financial data. Please try again.",
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.negative.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _handleLogout(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.negative,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Log out',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.negative,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Log out?',
      message: 'Are you sure you want to log out of FinAssist?',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;

    // Clears the whole stack (Dashboard, Profile, any pushed screens) so a
    // back gesture can never reveal a protected screen after logging out.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
  }
}
