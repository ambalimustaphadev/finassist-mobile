import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// Only shows permissions FinAssist actually requests. Photo library
/// access isn't listed: picking a photo from the gallery goes through the
/// OS's own out of process picker (see `ProfileImagePickerService`), which
/// never asks this app for a photo library grant at all, so showing a
/// status for it here would describe a permission the app doesn't use.
class ManageAppPermissionsScreen extends StatefulWidget {
  const ManageAppPermissionsScreen({super.key});

  @override
  State<ManageAppPermissionsScreen> createState() =>
      _ManageAppPermissionsScreenState();
}

class _ManageAppPermissionsScreenState extends State<ManageAppPermissionsScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _camera;
  PermissionStatus? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refreshes when returning from the system Settings app, so a change
    // made there is reflected here without needing to leave and reopen
    // this screen.
    if (state == AppLifecycleState.resumed) _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    PermissionStatus camera;
    PermissionStatus notifications;
    try {
      camera = await Permission.camera.status;
    } catch (_) {
      camera = PermissionStatus.denied;
    }
    try {
      notifications = await Permission.notification.status;
    } catch (_) {
      notifications = PermissionStatus.denied;
    }
    if (!mounted) return;
    setState(() {
      _camera = camera;
      _notifications = notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Manage app permissions', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              "What FinAssist can access on your device.",
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PermissionRow(
              icon: Icons.camera_alt_outlined,
              title: 'Camera',
              explanation: 'Used to take a profile photo.',
              status: _camera,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PermissionRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              explanation:
                  'Used to send you updates about your account and '
                  'documents.',
              status: _notifications,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.explanation,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String explanation;
  final PermissionStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: openAppSettings,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: icon, color: AppColors.accentStrong),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium),
                    const SizedBox(height: 2),
                    Text(explanation, style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      status == null ? 'Checking...' : _label(status),
                      style: AppTypography.caption.copyWith(
                        color: status != null && status.isGranted
                            ? AppColors.accentStrong
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return 'Allowed';
    if (status.isPermanentlyDenied) return 'Blocked in Settings';
    return 'Not allowed';
  }
}
