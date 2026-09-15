import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/preferences_controller.dart';

/// Real toggles backed by `PATCH /api/preferences` — distinct from the
/// notification *inbox* (reached from the bell icon), this is about what
/// FinAssist is allowed to notify about, not viewing past ones.
///
/// These toggles only control what FinAssist is allowed to send, not
/// whether the device lets it show anything at all — if the OS-level
/// notification permission is off, that's shown separately so the two
/// never get confused with each other.
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _osPermission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOsPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshOsPermission();
  }

  Future<void> _refreshOsPermission() async {
    PermissionStatus status;
    try {
      status = await Permission.notification.status;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _osPermission = status);
  }

  @override
  Widget build(BuildContext context) {
    final preferencesState = ref.watch(preferencesControllerProvider);
    final preferences = preferencesState.preferences;
    final notifier = ref.read(preferencesControllerProvider.notifier);
    final osBlocked =
        _osPermission != null &&
        !_osPermission!.isGranted &&
        !_osPermission!.isLimited;

    ref.listen(preferencesControllerProvider, (previous, next) {
      if (next.saveError != null && next.saveError != previous?.saveError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.surfaceElevated,
              content: Text(
                next.saveError!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        notifier.dismissSaveError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Notifications', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: preferences == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2.5,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Choose which updates FinAssist can send you.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (osBlocked) ...[
                    _OsBlockedBanner(onOpenSettings: openAppSettings),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ToggleRow(
                    title: 'All notifications',
                    subtitle: 'Turn every notification below on or off at once',
                    value: preferences.notificationsEnabled,
                    onChanged: preferencesState.isSaving
                        ? null
                        : (value) =>
                              notifier.update({'notifications_enabled': value}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ToggleRow(
                    title: 'Document notifications',
                    subtitle: 'Updates about your uploaded documents',
                    value: preferences.documentNotifications,
                    onChanged: preferencesState.isSaving
                        ? null
                        : (value) => notifier.update({
                            'document_notifications': value,
                          }),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OsBlockedBanner extends StatelessWidget {
  const _OsBlockedBanner({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are turned off for FinAssist on this '
                  'device.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  "These settings won't take effect until you allow "
                  'notifications in system settings.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onOpenSettings,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Open settings',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
