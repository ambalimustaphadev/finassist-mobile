import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/subscription.dart';
import '../../domain/subscription_brand.dart';

/// Resolves and renders a subscription's icon — a known brand's logo, a
/// category fallback, or a generic "other" icon, per [resolveIconAsset].
/// Always renders a real asset, never a broken-image glyph.
class SubscriptionIcon extends StatelessWidget {
  const SubscriptionIcon({
    super.key,
    required this.name,
    this.category,
    this.size = 44,
  });

  final String name;
  final SubscriptionCategory? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = resolveIconAsset(name: name, category: category);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.27),
      child: Container(
        width: size,
        height: size,
        color: context.colors.surfaceHighlight,
        padding: EdgeInsets.all(size * 0.16),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
