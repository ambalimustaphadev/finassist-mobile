import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../providers/shell_providers.dart';

/// The shared top bar used across FinAssist's main tabs: a menu button
/// that opens the conversation-history drawer, the FinAssist brand mark
/// with a contextual [subtitle], and an avatar that jumps to Profile.
/// Reused by Chat (with a dynamic online/offline subtitle), Quick and
/// Tools (with a static tagline) so the app's chrome reads as one
/// consistent identity everywhere except Profile, which is the
/// destination that chrome points to.
class MainHeaderBar extends ConsumerWidget {
  const MainHeaderBar({
    super.key,
    required this.subtitle,
    this.showMenu = true,
  });

  final Widget subtitle;

  /// Whether the leading menu icon (opens the conversation drawer) is
  /// shown — every host screen needs its own `Scaffold(drawer: ...)` for
  /// this to have anywhere to open.
  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pictureUrl = ref.watch(
      profileControllerProvider.select((s) => s.profile?.profilePictureUrl),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (showMenu)
            _HeaderIconButton(
              icon: Icons.menu_rounded,
              semanticLabel: 'Open menu',
              onTap: () => Scaffold.of(context).openDrawer(),
            )
          else
            const SizedBox(width: AppSpacing.sm),
          const SizedBox(width: AppSpacing.xs),
          const _BrandMark(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FinAssist',
                  style: AppTypography.screenTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle,
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Open profile',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () =>
                  ref.read(mainTabProvider.notifier).state = profileTabIndex,
              child: UserAvatar(
                imageUrl: pictureUrl,
                size: 34,
                onImageError: pictureUrl == null
                    ? null
                    : () => WidgetsBinding.instance.addPostFrameCallback(
                        (_) => ref
                            .read(profileControllerProvider.notifier)
                            .refreshIfPictureUrlStale(pictureUrl),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain "Your financial AI companion" tagline — the default subtitle
/// for screens that aren't tracking a live status (Quick, Tools).
class BrandTagline extends StatelessWidget {
  const BrandTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Your financial AI companion',
      style: AppTypography.caption,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.eco_rounded,
        color: AppColors.accentDeep,
        size: 17,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
