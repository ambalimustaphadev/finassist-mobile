import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/extensions/formatting_extensions.dart';

const _avatarPalette = [
  Color(0xFFE8654A),
  Color(0xFF4F9EF0),
  Color(0xFFF2994A),
  Color(0xFF9B87F5),
  Color(0xFF2EDB87),
];

/// A single transaction/summary row inside the AI financial breakdown card,
/// e.g. "KFC, Bodija · May 28, 2024 · ₦18,500".
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;

  /// When set, renders this icon in the avatar instead of initials.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final avatarColor =
        _avatarPalette[title.hashCode.abs() % _avatarPalette.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, size: 16, color: avatarColor)
                : Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: AppTypography.bodyMedium.copyWith(
                      color: avatarColor,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            amount.toNaira(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
