import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/models/preferences.dart';
import '../providers/preferences_controller.dart';

/// Combines what used to be two separate Profile rows (Language, Currency)
/// into one screen, matching the new Preferences group. Both still persist
/// through the same real `PATCH /api/preferences` fields as before —
/// currency still feeds the Tools calculators, this only changes where the
/// picker lives.
class LanguageCurrencyScreen extends ConsumerWidget {
  const LanguageCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(preferencesControllerProvider);
    final notifier = ref.read(preferencesControllerProvider.notifier);

    ref.listen(preferencesControllerProvider, (previous, next) {
      if (next.saveError != null && next.saveError != previous?.saveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.colors.surfaceElevated,
              content: Text(
                next.saveError!,
                style: TextStyle(color: context.colors.textPrimary),
              ),
            ),
          );
        notifier.dismissSaveError();
      }
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text('Language & currency', style: AppTypography.screenTitle(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _SectionLabel(label: 'Language'),
            Text(
              "Your preference is saved, but FinAssist's interface is "
              'English only today. Full translation is coming.',
              style: AppTypography.caption(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final option in supportedLanguages)
              _OptionRow(
                label: option.label,
                selected: option.code == preferencesState.language,
                onTap: preferencesState.isSaving
                    ? null
                    : () => notifier.setLanguage(option.code),
              ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel(label: 'Currency'),
            Text(
              'Choose how FinAssist displays currency in conversations and '
              'calculations.',
              style: AppTypography.caption(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final option in supportedCurrencies)
              _CurrencyOptionRow(
                option: option,
                selected: option.code == preferencesState.currency,
                onTap: preferencesState.isSaving
                    ? null
                    : () => notifier.setCurrency(option.code),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: AppTypography.bodyMedium(context).copyWith(color: context.colors.textPrimary),
      ),
    );
  }
}

class _CurrencyOptionRow extends StatelessWidget {
  const _CurrencyOptionRow({
    required this.option,
    required this.selected,
    this.onTap,
  });

  final CurrencyOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(option.symbol, style: AppTypography.sectionHeading(context)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.code, style: AppTypography.bodyMedium(context)),
                      Text(option.label, style: AppTypography.caption(context)),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.colors.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: AppTypography.bodyMedium(context))),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.colors.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
