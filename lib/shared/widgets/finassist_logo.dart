import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

/// The one official FinAssist logo/brand mark ([AppAssets.finAssistLogo]),
/// rendered consistently wherever the app needs to show it — splash,
/// onboarding, auth, the chat drawer, About FinAssist, the main header.
/// Never redrawn, recolored or approximated with an icon; always this
/// same asset, just at whatever [size] (or [width]/[height]) the context
/// calls for.
class FinAssistLogo extends StatelessWidget {
  const FinAssistLogo({super.key, this.size, this.width, this.height});

  /// Convenience for a square logo — sets both [width] and [height].
  /// Ignored for either dimension explicitly overridden by [width]/[height].
  final double? size;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? size;
    final resolvedHeight = height ?? size;

    return Image.asset(
      AppAssets.finAssistLogo,
      width: resolvedWidth,
      height: resolvedHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          SizedBox(width: resolvedWidth, height: resolvedHeight),
    );
  }
}
