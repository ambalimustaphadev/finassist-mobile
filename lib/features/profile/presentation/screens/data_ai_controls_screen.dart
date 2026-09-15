import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/preferences_controller.dart';
import '../widgets/profile_section.dart';
import 'manage_app_permissions_screen.dart';

/// Real controls only: `proactive_suggestions` is a genuine, persisted
/// `PATCH /api/preferences` field (the same one set on the personalization
/// flow's response style page). There's no backend support for opting out
/// of AI processing itself, exporting data, or a "don't use my data for
/// training" flag, so none of those appear as switches with nothing
/// behind them.
class DataAiControlsScreen extends ConsumerWidget {
  const DataAiControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(preferencesControllerProvider);
    final preferences = preferencesState.preferences;
    final notifier = ref.read(preferencesControllerProvider.notifier);

    ref.listen(preferencesControllerProvider, (previous, next) {
      if (next.saveError != null && next.saveError != previous?.saveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.surfaceElevated,
              content: Text(
                next.saveError!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        notifier.dismissSaveError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Data & AI controls', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: preferences == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2.5,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Control how your information is used with FinAssist.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'FinAssist uses artificial intelligence to understand '
                    'your questions and generate responses. Answers can '
                    'sometimes be incomplete or incorrect, so review '
                    'important information before making a financial '
                    'decision.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proactive suggestions',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                'Let FinAssist occasionally share helpful '
                                'tips and things to consider during a '
                                'conversation.',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: preferences.proactiveSuggestions,
                          onChanged: preferencesState.isSaving
                              ? null
                              : (value) => notifier.update({
                                  'proactive_suggestions': value,
                                }),
                          activeThumbColor: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const ProfileSectionLabel(label: 'More controls'),
                  ProfileSectionCard(
                    children: [
                      ProfileMenuRow(
                        icon: Icons.vpn_key_outlined,
                        iconColor: AppColors.categoryTransfers,
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
