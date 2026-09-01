import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The small sparkle-in-circle avatar representing the FinAssist AI,
/// used in the chat app bar and next to every AI message bubble.
class AIAvatar extends StatelessWidget {
  const AIAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_awesome_rounded,
        color: AppColors.accent,
        size: size * 0.5,
      ),
    );
  }
}
