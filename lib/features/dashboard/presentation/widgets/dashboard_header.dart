import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/profile_image_controller.dart';
import '../providers/dashboard_providers.dart';
import 'app_bottom_nav_bar.dart' show profileNavIndex;

/// Top bar of the dashboard: menu icon, notification bell and profile
/// avatar. Menu and notifications have no destination screen yet, so taps
/// are intentionally inert beyond a subtle ripple; the avatar opens
/// Profile.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(icon: Icons.menu_rounded, onTap: () {}),
        Row(
          children: [
            _NotificationButton(onTap: () {}),
            const SizedBox(width: AppSpacing.md),
            const _ProfileAvatar(),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends ConsumerWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = ref.watch(
      profileImageControllerProvider.select((state) => state.imagePath),
    );

    return Semantics(
      button: true,
      label: 'Open profile',
      child: InkWell(
        key: const Key('dashboardProfileAvatar'),
        customBorder: const CircleBorder(),
        onTap: () =>
            ref.read(dashboardTabProvider.notifier).state = profileNavIndex,
        child: UserAvatar(imagePath: imagePath, size: 36, iconSize: 20),
      ),
    );
  }
}
