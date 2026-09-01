import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/services/profile_image_picker_service.dart';

/// A themed action sheet offering the three ways to set a profile
/// picture — resolves to the [ProfileImageSource] the user picked, or
/// `null` if they cancelled (tapped "Cancel" or dismissed the sheet).
Future<ProfileImageSource?> showProfileImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ProfileImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ProfileImageSourceSheet(),
  );
}

class _ProfileImageSourceSheet extends StatelessWidget {
  const _ProfileImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change profile picture', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.md),
            _SourceRow(
              icon: Icons.photo_outlined,
              title: 'Photos',
              subtitle: 'Choose from your photos',
              onTap: () =>
                  Navigator.of(context).pop(ProfileImageSource.gallery),
            ),
            _SourceRow(
              icon: Icons.photo_camera_outlined,
              title: 'Take photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.of(context).pop(ProfileImageSource.camera),
            ),
            _SourceRow(
              icon: Icons.insert_drive_file_outlined,
              title: 'Choose file',
              subtitle: 'Select an image file',
              onTap: () => Navigator.of(context).pop(ProfileImageSource.file),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
