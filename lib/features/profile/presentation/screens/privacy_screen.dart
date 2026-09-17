import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../widgets/profile_section.dart';
import 'data_ai_controls_screen.dart';
import 'manage_app_permissions_screen.dart';

/// What FinAssist actually collects and why, in plain language. Every
/// category listed here is something the app genuinely handles today —
/// nothing is described that isn't real, and nothing real is left out to
/// look simpler than it is.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text('Privacy', style: AppTypography.screenTitle(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'What FinAssist knows about you, and why.',
              style: AppTypography.body(context).copyWith(color: context.colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _Category(
              title: 'Account information',
              body:
                  'Your name, username, email and preferences are stored so '
                  'you can sign in and FinAssist behaves the way you set '
                  'it up.',
            ),
            const _Category(
              title: 'Conversations',
              body:
                  'Messages you send and the replies you get are saved so '
                  'you can come back to a conversation later.',
            ),
            const _Category(
              title: 'Financial documents',
              body:
                  'Statements or files you choose to upload are stored '
                  'securely and used to answer your questions about them. '
                  "You decide what to share, and you can remove it.",
            ),
            const _Category(
              title: 'Device permissions',
              body:
                  'FinAssist only asks for camera access when you choose to '
                  'take a profile photo, and for notification permission if '
                  'you allow it.',
            ),
            const _Category(
              title: 'AI processing',
              body:
                  'FinAssist uses OpenAI to understand your questions and '
                  'generate responses. What you send, including anything '
                  "you've chosen to share, may be sent to OpenAI to produce "
                  'a reply.',
            ),
            const SizedBox(height: AppSpacing.md),
            const ProfileSectionLabel(label: 'Manage'),
            ProfileSectionCard(
              children: [
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
          ],
        ),
      ),
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodyMedium(context)),
          const SizedBox(height: 4),
          Text(body, style: AppTypography.body(context)),
        ],
      ),
    );
  }
}
