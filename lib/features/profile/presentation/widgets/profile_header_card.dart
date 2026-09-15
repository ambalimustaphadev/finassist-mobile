import 'dart:io';

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
import '../../data/models/profile.dart';
import '../../data/services/profile_image_picker_service.dart';
import '../providers/profile_controller.dart';
import 'profile_image_source_sheet.dart';

/// The Profile page header: avatar (with a tap-to-change camera
/// affordance), full name, @username and email — the real,
/// backend-authoritative `/api/profile` data whenever it's loaded.
///
/// If `/api/profile` is temporarily unavailable (and its one automatic
/// retry — see `ProfileController._load` — also failed), identity text
/// falls back to `authControllerProvider`'s already-authenticated
/// `AuthUser` instead of going blank: that's the same first/last name/
/// username/email FinAssist already got back from login/register/session
/// restore and has held for the whole session regardless of `/api/profile`
/// — not a new data source, just not *ignoring* one that's already known.
/// Anything `/api/profile`-only (the picture, currency, etc.) still simply
/// isn't shown until that request actually succeeds.
class ProfileHeaderCard extends ConsumerStatefulWidget {
  const ProfileHeaderCard({super.key});

  @override
  ConsumerState<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends ConsumerState<ProfileHeaderCard> {
  /// The just-picked (not yet uploaded/confirmed) local file — shown
  /// immediately so the user sees their choice without waiting on the
  /// upload, then cleared once the real `profile_picture_url` takes over.
  String? _localPreviewPath;
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    // Only ever consulted when `profile` is null (see `_displayName`/
    // `_displayUsername`/`_displayEmail` below) — cheap to read
    // unconditionally since it's already-computed session state, not a
    // new fetch.
    final authUser = ref.watch(authControllerProvider.select((s) => s.user));

    ref.listen(profileControllerProvider, (previous, next) {
      if (next.pictureError != null &&
          next.pictureError != previous?.pictureError) {
        setState(() => _localPreviewPath = null);
        _showError(context, next.pictureError!, false);
        ref.read(profileControllerProvider.notifier).dismissPictureError();
      }
    });

    final isBusy = _isPicking || profileState.isUploadingPicture;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                imagePath: _localPreviewPath,
                imageUrl: profile?.profilePictureUrl,
                size: 76,
                iconSize: 40,
                onImageError: profile?.profilePictureUrl == null
                    ? null
                    : () => WidgetsBinding.instance.addPostFrameCallback(
                        (_) => ref
                            .read(profileControllerProvider.notifier)
                            .refreshIfPictureUrlStale(
                              profile!.profilePictureUrl!,
                            ),
                      ),
              ),
              if (isBusy)
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
                      onTap: isBusy
                          ? null
                          : () => _changeProfilePicture(context),
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
                  Text(
                    _displayName(profile, authUser),
                    style: AppTypography.sectionHeading,
                  ),
                  if (_displayUsername(profile, authUser).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${_displayUsername(profile, authUser)}',
                      style: AppTypography.body,
                    ),
                  ],
                  if (_displayEmail(profile, authUser).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _displayEmail(profile, authUser),
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePicture(BuildContext context) async {
    final source = await showProfileImageSourceSheet(context);
    if (source == null) return;

    setState(() => _isPicking = true);
    final result = await ref
        .read(profileImagePickerServiceProvider)
        .pickAndPersistProfileImage(
          ref.read(profileControllerProvider.notifier).userId,
          source,
        );
    if (!mounted) return;
    setState(() => _isPicking = false);

    switch (result.outcome) {
      case ProfileImagePickOutcome.success:
        setState(() => _localPreviewPath = result.filePath);
        await ref
            .read(profileControllerProvider.notifier)
            .uploadProfilePicture(File(result.filePath!));
        if (mounted) setState(() => _localPreviewPath = null);
      case ProfileImagePickOutcome.cancelled:
        break;
      case ProfileImagePickOutcome.permissionDenied:
        if (context.mounted) {
          _showError(context, _permissionDeniedMessage(source), false);
        }
      case ProfileImagePickOutcome.permissionPermanentlyDenied:
        if (context.mounted) {
          _showError(
            context,
            _permissionPermanentlyDeniedMessage(source),
            true,
          );
        }
      case ProfileImagePickOutcome.invalidImage:
        if (context.mounted) {
          _showError(
            context,
            "Couldn't use that image. Please try a different one.",
            false,
          );
        }
    }
  }

  /// The name to show: the loaded profile's, or — only when there is no
  /// profile at all — the already-authenticated session's.
  String _displayName(Profile? profile, AuthUser? authUser) {
    if (profile != null) {
      return profile.fullName.isEmpty ? profile.username : profile.fullName;
    }
    if (authUser == null) return '';
    final fullName = '${authUser.firstName} ${authUser.lastName}'.trim();
    return fullName.isEmpty ? authUser.username : fullName;
  }

  String _displayUsername(Profile? profile, AuthUser? authUser) {
    if (profile != null) return profile.username;
    return authUser?.username ?? '';
  }

  String _displayEmail(Profile? profile, AuthUser? authUser) {
    if (profile != null) return profile.email;
    return authUser?.email ?? '';
  }

  String _permissionDeniedMessage(ProfileImageSource source) {
    return source == ProfileImageSource.camera
        ? 'FinAssist needs camera access to take a profile photo.'
        : 'FinAssist needs access to your photos to choose a profile picture.';
  }

  String _permissionPermanentlyDeniedMessage(ProfileImageSource source) {
    final need = source == ProfileImageSource.camera
        ? 'FinAssist needs camera access to take a profile photo.'
        : 'FinAssist needs access to your photos to choose a profile picture.';
    return "$need You'll need to allow it from Settings.";
  }

  void _showError(BuildContext context, String message, bool canOpenSettings) {
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
  }
}
