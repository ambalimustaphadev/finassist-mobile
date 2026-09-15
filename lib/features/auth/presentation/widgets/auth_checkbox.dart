import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// A compact checkbox glyph for auth screens ("Remember me", "I agree to
/// the Terms...") — a plain toggling `Icon`, not Material's `Checkbox`,
/// which enforces a much larger minimum tap-target box that doesn't fit
/// this design's tight, inline rows without overflowing on narrower
/// screens.
class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({super.key, required this.value, this.size = 20});

  final bool value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
      size: size,
      color: value ? AppColors.accentDeep : AppColors.authTextMuted,
    );
  }
}
