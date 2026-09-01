import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/confirm_action_dialog.dart';
import '../../data/models/conversation.dart';
import '../providers/chat_controller.dart';

/// The chat screen's side menu: brand mark, "+ New conversation", and the
/// list of recent conversations with meaningful titles and relative dates.
class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final notifier = ref.read(chatControllerProvider.notifier);

    // The active thread shouldn't also show up in its own recents list.
    final recents = chatState.conversations
        .where((c) => c.id != chatState.currentConversationId)
        .toList();

    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text('FinAssist', style: AppTypography.screenTitle),
            ),
            _NewConversationRow(
              onTap: () {
                notifier.startNewConversation();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (recents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'RECENT',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: recents.isEmpty
                  ? const _NoRecentConversations()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: recents.length,
                      itemBuilder: (context, index) {
                        final conversation = recents[index];
                        return _ConversationTile(
                          conversation: conversation,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await notifier.openConversation(conversation.id);
                          },
                          onDelete: () =>
                              _handleDelete(context, notifier, conversation),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleDelete(
  BuildContext context,
  ChatController notifier,
  Conversation conversation,
) async {
  final confirmed = await showConfirmActionDialog(
    context,
    title: 'Delete conversation?',
    message: 'This conversation will be permanently deleted.',
    confirmLabel: 'Delete',
    isDestructive: true,
  );
  if (!confirmed) return;
  await notifier.deleteConversation(conversation.id);
}

class _NewConversationRow extends StatelessWidget {
  const _NewConversationRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New conversation',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                'New conversation',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: conversation.title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.updatedAt.toRelativeConversationDate(),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Conversation options',
                child: PopupMenuButton<_ConversationAction>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  color: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onSelected: (action) {
                    if (action == _ConversationAction.delete) onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ConversationAction.delete,
                      child: Text(
                        'Delete',
                        style: AppTypography.body.copyWith(
                          color: AppColors.negative,
                        ),
                      ),
                    ),
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

enum _ConversationAction { delete }

class _NoRecentConversations extends StatelessWidget {
  const _NoRecentConversations();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        'Your recent conversations will show up here.',
        style: AppTypography.body,
      ),
    );
  }
}
