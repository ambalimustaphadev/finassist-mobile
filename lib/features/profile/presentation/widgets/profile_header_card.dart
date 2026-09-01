import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/data/models/auth_user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_image_controller.dart';
import 'profile_image_source_sheet.dart';

/// The Profile page header: avatar (with a tap-to-change camera
/// affordance), full name, @username and email — always the currently
/// authenticated user's real data, never hardcoded.
class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(
      authControllerProvider.select((state) => state.user),
    );
    final imageState = ref.watch(profileImageControllerProvider);
    final notifier = ref.read(profileImageControllerProvider.notifier);

    ref.listen(profileImageControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showError(context, next.errorMessage!, next.canOpenSettings, notifier);
      }
    });

    final username = user?.username;
    final email = user?.email;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                imagePath: imageState.imagePath,
                size: 76,
                iconSize: 40,
              ),
              if (imageState.isPicking)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Semantics(
                  button: true,
                  label: 'Change profile picture',
                  child: Material(
                    color: AppColors.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: imageState.isPicking
                          ? null
                          : () => _changeProfilePicture(context, notifier),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fullName(user), style: AppTypography.sectionHeading),
                  if (username != null && username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('@$username', style: AppTypography.body),
                  ],
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(email, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the "Photos / Take photo / Choose file" action sheet and, if
  /// the user picks one, hands the chosen source off to the controller —
  /// cancelling the sheet itself never touches `notifier.pickImage`, so no
  /// permission is ever requested until the user has actually chosen how
  /// they want to provide a picture.
  Future<void> _changeProfilePicture(
    BuildContext context,
    ProfileImageController notifier,
  ) async {
    final source = await showProfileImageSourceSheet(context);
    if (source == null) return;
    await notifier.pickImage(source);
  }

  String _fullName(AuthUser? user) {
    if (user == null) return '';
    final name = '${user.firstName} ${user.lastName}'.trim();
    return name.isEmpty ? user.username : name;
  }

  void _showError(
    BuildContext context,
    String message,
    bool canOpenSettings,
    ProfileImageController notifier,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 5),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          action: canOpenSettings
              ? SnackBarAction(
                  label: 'Open Settings',
                  textColor: AppColors.accent,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
    notifier.dismissError();
  }
}
