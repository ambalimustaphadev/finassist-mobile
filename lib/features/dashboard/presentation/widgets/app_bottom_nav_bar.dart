import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/dashboard_providers.dart';

class _NavItem {
  const _NavItem(this.icon, this.label, {this.isImplemented = false});

  final IconData icon;
  final String label;

  /// Whether this tab actually has a destination to switch to yet.
  final bool isImplemented;
}

const _navItems = [
  _NavItem(Icons.home_rounded, 'Home', isImplemented: true),
  _NavItem(Icons.swap_horiz_rounded, 'Transactions'),
  _NavItem(Icons.insights_rounded, 'Insights'),
  _NavItem(Icons.track_changes_rounded, 'Goals'),
  _NavItem(Icons.person_rounded, 'Profile', isImplemented: true),
];

/// The index of the Profile tab within [_navItems] — shared with
/// [dashboardTabProvider]'s consumers so switching to Profile (from here
/// or from the dashboard avatar shortcut) always means the same thing.
const profileNavIndex = 4;

/// Bottom navigation for the dashboard shell. Only "Home" and "Profile"
/// are implemented; the remaining items surface a lightweight "coming
/// soon" cue rather than dead-ending into unbuilt screens. Tapping Home or
/// Profile switches [dashboardTabProvider] in place rather than pushing a
/// new route, so this bar stays on screen no matter which tab is active.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(dashboardTabProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _navItems.length; i++)
              Expanded(
                child: _NavButton(
                  item: _navItems[i],
                  isActive: i == selectedIndex,
                  onTap: () => _handleTap(context, ref, i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, int index) {
    final item = _navItems[index];
    if (item.isImplemented) {
      ref.read(dashboardTabProvider.notifier).state = index;
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            '${item.label} is coming soon',
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
        ),
      );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textMuted;
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.navLabel.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
