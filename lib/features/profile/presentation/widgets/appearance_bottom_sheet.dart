import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// Opens the Appearance picker — lets the user choose System/Light/Dark,
/// applying the choice immediately via [themeModeControllerProvider] (see
/// `ThemeModeController`, which persists it and `MaterialApp` watches it
/// directly, so the whole app re-themes with no restart needed).
Future<void> showAppearanceBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AppearanceBottomSheet(),
  );
}

class _AppearanceBottomSheet extends ConsumerWidget {
  const _AppearanceBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(themeModeControllerProvider);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: AppTypography.sectionHeading(context)),
            const SizedBox(height: 2),
            Text(
              'Choose how FinAssist looks',
              style: AppTypography.caption(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _AppearanceOptionRow(
              icon: Icons.brightness_auto_rounded,
              title: 'System',
              subtitle: 'Follow device setting',
              active: activeMode == ThemeMode.system,
              onTap: () => _select(context, ref, ThemeMode.system),
            ),
            _AppearanceOptionRow(
              icon: Icons.light_mode_rounded,
              title: 'Light',
              subtitle: 'Bright and clean',
              active: activeMode == ThemeMode.light,
              onTap: () => _select(context, ref, ThemeMode.light),
            ),
            _AppearanceOptionRow(
              icon: Icons.dark_mode_rounded,
              title: 'Dark',
              subtitle: 'Easy on the eyes',
              active: activeMode == ThemeMode.dark,
              onTap: () => _select(context, ref, ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, ThemeMode mode) {
    ref.read(themeModeControllerProvider.notifier).setThemeMode(mode);
    Navigator.of(context).pop();
  }
}

class _AppearanceOptionRow extends StatelessWidget {
  const _AppearanceOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? context.colors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, color: context.colors.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium(context)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption(context)),
                  ],
                ),
              ),
              if (active)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
