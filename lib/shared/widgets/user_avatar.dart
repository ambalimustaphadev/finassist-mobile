import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The user's profile picture if one is set, otherwise the same tinted
/// person-icon circle used throughout FinAssist. Shared by the Dashboard
/// header and the Profile page so both stay visually and behaviorally in
/// sync — never a broken image, never a random placeholder.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.imagePath, this.size = 36, this.iconSize});

  /// On-device path of the user's chosen profile picture, or null/empty to
  /// fall back to the default person icon.
  final String? imagePath;

  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final resolvedIconSize = iconSize ?? size * 0.55;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

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
      child: hasImage
          ? Image.file(
              File(imagePath!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: resolvedIconSize,
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: AppColors.textSecondary,
              size: resolvedIconSize,
            ),
    );
  }
}
