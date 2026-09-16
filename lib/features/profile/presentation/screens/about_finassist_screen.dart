import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/finassist_logo.dart';

/// Version comes straight from `pubspec.yaml` (`1.0.0+1`) — there's no
/// `package_info_plus` (or similar) dependency in this project to read it
/// at runtime, so rather than adding a new package for one string, this
/// stays a literal kept in sync with `pubspec.yaml` by hand, same as the
/// About dialog it replaces already did.
const _appVersion = '1.0.0';
const _appBuild = '1';

class AboutFinAssistScreen extends StatelessWidget {
  const AboutFinAssistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('About FinAssist', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Column(
                children: [
                  const FinAssistLogo(size: 72),
                  const SizedBox(height: AppSpacing.md),
                  Text('FinAssist', style: AppTypography.greeting),
                  const SizedBox(height: 2),
                  Text(
                    'Your AI financial companion.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version $_appVersion ($_appBuild)',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'FinAssist helps you make sense of money through natural '
              'conversation. Ask questions, understand financial '
              'concepts, explore decisions and get clearer answers from '
              "the information you choose to share.",
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _CapabilityRow(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Ask',
              body: 'Ask questions about money in plain language.',
            ),
            const _CapabilityRow(
              icon: Icons.description_outlined,
              title: 'Understand',
              body:
                  'Turn complex financial information into something '
                  'easier to understand.',
            ),
            const _CapabilityRow(
              icon: Icons.calculate_outlined,
              title: 'Calculate',
              body:
                  'Use practical tools to work through financial '
                  'calculations.',
            ),
            const _CapabilityRow(
              icon: Icons.explore_outlined,
              title: 'Explore',
              body:
                  'Think through financial decisions with clearer '
                  'information.',
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'FinAssist uses artificial intelligence to understand your '
              'questions, work with information you provide and generate '
              'responses. AI responses can sometimes be incomplete or '
              'incorrect, so review important information before making '
              'financial decisions.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'FinAssist provides AI generated information and analysis '
                'for educational and decision support purposes. It is not '
                'a substitute for professional financial, legal, tax or '
                'investment advice. Always verify important decisions '
                'with an appropriately qualified professional.',
                style: AppTypography.caption,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'FinAssist',
                  applicationVersion: '$_appVersion ($_appBuild)',
                ),
                child: Text(
                  'Open source licenses',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentStrong, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(body, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
