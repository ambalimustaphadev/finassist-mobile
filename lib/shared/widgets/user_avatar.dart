import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The user's profile picture if one is set, otherwise the same tinted
/// person-icon circle used throughout FinAssist. Shared by the chat
/// header/drawer and the Profile page so all three stay visually and
/// behaviorally in sync — never a broken image, never a random
/// placeholder.
///
/// [imagePath] (a local file) takes priority over [imageUrl] (the real,
/// backend `profile_picture_url`) when both are given — that's only true
/// for the brief moment between picking a new photo and the upload
/// finishing, so the user sees their choice immediately instead of a
/// spinner-then-swap.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.size = 36,
    this.iconSize,
    this.onImageError,
  });

  /// On-device path of a just-picked (not yet uploaded) profile picture.
  final String? imagePath;

  /// The real, persisted `profile_picture_url` from the backend — a
  /// temporary, backend-generated signed URL, never something this widget
  /// (or anything in Flutter) constructs itself.
  final String? imageUrl;

  final double size;
  final double? iconSize;

  /// Called when [imageUrl] fails to load — e.g. its signed URL has
  /// expired. Never called for an [imagePath] failure (that's a local
  /// file, unrelated to the backend). Callers typically use this to
  /// request a fresh profile (and thus a fresh signed URL) at most once;
  /// this widget itself never retries or polls.
  final VoidCallback? onImageError;

  @override
  Widget build(BuildContext context) {
    final resolvedIconSize = iconSize ?? size * 0.55;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 1.5),
        gradient: const LinearGradient(
          colors: [AppColors.surfaceHighlight, AppColors.surfaceElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: _resolveImage(resolvedIconSize),
    );
  }

  Widget _resolveImage(double resolvedIconSize) {
    final fallback = Icon(
      Icons.person_rounded,
      color: AppColors.textSecondary,
      size: resolvedIconSize,
    );

    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.file(
        File(imagePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        // Forces a fresh fetch the instant the URL changes (e.g. right
        // after uploading a new picture) instead of `Image.network`'s
        // default caching potentially showing the previous photo.
        key: ValueKey(imageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          onImageError?.call();
          return fallback;
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      );
    }

    return fallback;
  }
}
