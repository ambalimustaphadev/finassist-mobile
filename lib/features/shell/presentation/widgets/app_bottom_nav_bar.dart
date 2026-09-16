import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/shell_providers.dart';

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const _navItems = [
  _NavItem(Icons.chat_bubble_rounded, 'Chat'),
  _NavItem(Icons.receipt_long_rounded, 'Track'),
  _NavItem(Icons.calculate_rounded, 'Tools'),
  _NavItem(Icons.person_rounded, 'Profile'),
];

/// Bottom navigation for FinAssist's main shell: Chat, Track, Tools,
/// Profile — no Dashboard, no History, no separate Upload tab. Tapping any
/// tab switches [mainTabProvider] in place rather than pushing a new
/// route, so this bar (and the active tab's highlight) stays on screen no
/// matter which tab is active, including throughout an active
/// conversation.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainTabProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  onTap: () => _handleTap(ref, i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTap(WidgetRef ref, int index) {
    ref.read(mainTabProvider.notifier).state = index;
  }
}

/// A flat nav button: icon sits above its label, and both always live
/// inside the exact same container — the active tint wraps that whole
/// icon+label group, never just the icon with the label sitting outside
/// it. Inactive tabs keep the identical structure, just transparent and
/// muted, so switching tabs only recolors/resizes a pill already
/// centered in its own slot rather than restructuring anything.
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
    final color = isActive ? AppColors.accentDeep : AppColors.textMuted;
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      // Centers the pill via `Row`/`RenderFlex` rather than `Center`/
      // `Align` (`RenderPositionedBox`) — the latter was observed
      // corrupting an unrelated icon's layout elsewhere in the app once
      // mounted. The pill is wrapped in `Flexible` (not a bare child) —
      // `Row` gives non-flex children an *unbounded* main-axis
      // constraint, so without it the pill would size to its natural
      // content width regardless of the slot, and could overflow on
      // narrow screens for a long label like "Profile". `Flexible` makes
      // it properly bounded to (at most) this slot's width while still
      // letting it stay narrower/content-sized when it fits, and the
      // label's own `overflow: ellipsis` is the last-resort safety net.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.onboardingMintTint
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.navLabel.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
