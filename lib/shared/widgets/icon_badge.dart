import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// A rounded, tinted icon badge reused for category icons, insight icons
/// and statement/document icons throughout the app.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundAlpha = 0.16,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double backgroundAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
