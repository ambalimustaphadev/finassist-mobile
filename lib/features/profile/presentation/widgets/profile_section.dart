import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// A section heading on the Profile page, e.g. "Account", "Your Finances".
class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.bodyMedium(context).copyWith(color: context.colors.textPrimary),
      ),
    );
  }
}

/// A card grouping related [ProfileMenuRow]s with a divider between each,
/// matching the reference design's section-card pattern using FinAssist's
/// existing `AppCard` surface.
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single tappable row inside a [ProfileSectionCard]: icon badge, title +
/// subtitle, and an optional trailing widget (count badge) before the
/// chevron.
class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive
        ? context.colors.negative
        : context.colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium(context).copyWith(
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(context),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
