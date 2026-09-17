import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../core/dev/dev_reset.dart';
import '../../../../shared/widgets/confirm_action_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../notifications/presentation/providers/notifications_controller.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../data/models/preferences.dart';
import '../providers/preferences_controller.dart';
import '../widgets/appearance_bottom_sheet.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_section.dart';
import 'about_finassist_screen.dart';
import 'change_password_screen.dart';
import 'contact_support_screen.dart';
import 'data_ai_controls_screen.dart';
import 'help_faq_screen.dart';
import 'language_currency_screen.dart';
import 'manage_app_permissions_screen.dart';
import 'notification_preferences_screen.dart';
import 'personal_information_screen.dart';
import 'privacy_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(preferencesControllerProvider);
    final languageLabel = languageOptionFor(preferencesState.language).label;
    final currencyOption = currencyOptionFor(preferencesState.currency);
    final hasUnreadNotifications = ref.watch(
      notificationsControllerProvider.select((s) => s.hasUnread),
    );
    final themeMode = ref.watch(themeModeControllerProvider);
    final themeModeLabel = switch (themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text('Profile', style: AppTypography.screenTitle(context)),
        actions: [
          Semantics(
            button: true,
            label: 'Notifications',
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: context.colors.textPrimary,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                if (hasUnreadNotifications)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 8, height: 8),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                  iconColor: context.colors.categoryBills,
                  title: 'Personal information',
                  subtitle: 'Update your name, username and email',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalInformationScreen(),
                    ),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.lock_outline_rounded,
                  iconColor: context.colors.accentStrong,
                  title: 'Change password',
                  subtitle: 'Update your password',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.shield_outlined,
                  iconColor: context.colors.categoryTransfers,
                  title: 'Security',
                  subtitle: 'Manage your account security',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SecurityScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Preferences'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.notifications_none_rounded,
                  iconColor: context.colors.categoryShopping,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationPreferencesScreen(),
                    ),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.brightness_6_outlined,
                  iconColor: context.colors.accentStrong,
                  title: 'Appearance',
                  subtitle: themeModeLabel,
                  onTap: () => showAppearanceBottomSheet(context),
                ),
                ProfileMenuRow(
                  icon: Icons.language_rounded,
                  iconColor: context.colors.categoryBills,
                  title: 'Language & currency',
                  subtitle:
                      '$languageLabel · ${currencyOption.symbol} '
                      '${currencyOption.code}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageCurrencyScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Privacy & data'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: context.colors.categoryBills,
                  title: 'Privacy',
                  subtitle: 'What FinAssist knows and why',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.tune_rounded,
                  iconColor: context.colors.accentStrong,
                  title: 'Data & AI controls',
                  subtitle: 'Control how your information is used',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DataAiControlsScreen(),
                    ),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.vpn_key_outlined,
                  iconColor: context.colors.categoryTransfers,
                  title: 'Manage app permissions',
                  subtitle: 'Camera and notification access',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageAppPermissionsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'Support'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.help_outline_rounded,
                  iconColor: context.colors.categoryBills,
                  title: 'Help & FAQ',
                  subtitle: 'Get help and find answers',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpFaqScreen()),
                  ),
                ),
                ProfileMenuRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: context.colors.accentStrong,
                  title: 'Contact support',
                  subtitle: 'Reach out to our support team',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            const ProfileSectionLabel(label: 'About'),
            ProfileSectionCard(
              children: [
                ProfileMenuRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: context.colors.categoryTransfers,
                  title: 'About FinAssist',
                  subtitle: 'Version 1.0.0',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AboutFinAssistScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            if (kDebugMode) ...[
              const ProfileSectionLabel(label: 'Development'),
              ProfileSectionCard(
                children: [
                  ProfileMenuRow(
                    icon: Icons.restart_alt_rounded,
                    iconColor: context.colors.negative,
                    title: 'Reset app state',
                    subtitle:
                        'Clear local session & onboarding state for testing',
                    isDestructive: true,
                    onTap: () => _handleDevReset(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],

            const _LogoutButton(),
          ],
        ),
      ),
    );
  }

  /// Debug-only (see the `kDebugMode` guard around this row): resets local
  /// auth/onboarding state so the existing AuthGate/routing logic resolves
  /// back to the first-launch flow (Onboarding -> Register, since this
  /// device now looks like it's never signed in) — never touches the
  /// backend or clears anything beyond what a real logout already clears
  /// locally, plus the onboarding-seen and initial-setup flags.
  Future<void> _handleDevReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Reset app state?',
      message:
          'This clears local FinAssist testing state (session and '
          'onboarding) and returns the app to the first-launch experience. '
          'Your account and data on the server are untouched.',
      confirmLabel: 'Reset',
      isDestructive: true,
    );
    if (!confirmed) return;

    await resetAppStateForDevelopment(ref);
    if (!context.mounted) return;

    // Same full-stack-clearing navigation as a real logout — a back
    // gesture must never reveal a protected screen after the reset either.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: context.colors.negative.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _handleLogout(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: context.colors.negative,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Log out',
                style: AppTypography.bodyMedium(context).copyWith(
                  color: context.colors.negative,
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
      title: 'Log out of FinAssist?',
      message: 'You can sign back in anytime.',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;

    // Clears the whole stack (Chat, Profile, any pushed screens) so a
    // back gesture can never reveal a protected screen after logging out.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.authGate, (route) => false);
  }
}
