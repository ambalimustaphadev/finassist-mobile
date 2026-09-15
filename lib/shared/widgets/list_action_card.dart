import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'app_card.dart';
import 'icon_badge.dart';

/// A tappable card: an icon badge, a title, an optional subtitle, and a
/// trailing chevron. Used across FinAssist wherever a list of named
/// actions/destinations needs the same shape — chat's prompt suggestions,
/// Tools' calculator grid, Profile's menu rows.
class ListActionCard extends StatelessWidget {
  const ListActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Tighter padding/spacing for grid layouts (e.g. Tools' 2-column grid)
  /// where cards are narrower than a full-width row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(dense ? AppSpacing.md : AppSpacing.lg),
      onTap: onTap,
      child: dense ? _denseLayout() : _rowLayout(),
    );
  }

  Widget _rowLayout() {
    return Row(
      children: [
        IconBadge(icon: icon, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ],
    );
  }

  Widget _denseLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconBadge(icon: icon, color: iconColor, size: 36, iconSize: 18),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: AppTypography.bodyMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTypography.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
