import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/models/notification.dart';
import '../providers/notifications_controller.dart';

/// The real notification inbox — reached only from Profile's bell icon.
/// An empty list is the honest, expected state today (the
/// backend has nothing that creates a notification yet); this says so
/// plainly rather than showing fabricated sample notifications.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Notifications', style: AppTypography.screenTitle),
        actions: [
          if (state.hasUnread)
            TextButton(
              onPressed: state.isMarkingAll ? null : notifier.markAllRead,
              child: Text(
                'Mark all read',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state.status) {
          NotificationsLoadStatus.loading => const LoadingStateView(
            height: 300,
          ),
          NotificationsLoadStatus.error => ErrorStateView(
            message: state.loadError ?? "Couldn't load your notifications.",
            onRetry: notifier.refresh,
          ),
          NotificationsLoadStatus.loaded when state.notifications.isEmpty =>
            const Center(
              child: EmptyStateView(
                icon: Icons.notifications_none_rounded,
                title: "You're all caught up",
                message:
                    "There's nothing here yet — we'll let you know when "
                    'something needs your attention.',
              ),
            ),
          NotificationsLoadStatus.loaded => RefreshIndicator(
            onRefresh: notifier.refresh,
            color: AppColors.accent,
            backgroundColor: AppColors.surfaceElevated,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index >= state.notifications.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: TextButton(
                        onPressed: state.isLoadingMore
                            ? null
                            : notifier.loadMore,
                        child: state.isLoadingMore
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent,
                                ),
                              )
                            : Text(
                                'Load more',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                      ),
                    ),
                  );
                }
                final notification = state.notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => notifier.markRead(notification.id),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(
                icon: Icons.notifications_rounded,
                color: notification.read
                    ? AppColors.textMuted
                    : AppColors.accentStrong,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: AppTypography.bodyMedium),
                    if (notification.body != null) ...[
                      const SizedBox(height: 2),
                      Text(notification.body!, style: AppTypography.caption),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                notification.createdAt.toRelativeConversationDate(),
                style: AppTypography.caption,
              ),
              if (!notification.read) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
