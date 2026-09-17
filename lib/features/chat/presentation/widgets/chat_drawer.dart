import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/confirm_action_dialog.dart';
import '../../../../shared/widgets/finassist_logo.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../shell/presentation/providers/shell_providers.dart';
import '../../data/models/conversation.dart';
import '../providers/chat_controller.dart';

/// FinAssist's side menu: brand header, "+ New chat", conversation search,
/// grouped recent conversations, Settings and the signed-in user — reached
/// from Chat, Track or Tools via their own `Scaffold(drawer:
/// ChatDrawer())`. All three instances read/write the same
/// `chatControllerProvider`, so opening a conversation from any of them
/// behaves identically and always lands on the Chat tab.
///
/// A light, premium surface (unlike the rest of the app's chrome) — a
/// deliberate visual register for "this is FinAssist's own space", the
/// same way the conversation-history side menu already stood apart before
/// this redesign, just lighter now instead of dark.
class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({super.key});

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final notifier = ref.read(chatControllerProvider.notifier);

    final hasAnyConversations = chatState.conversations.isNotEmpty;
    final filtered = _query.isEmpty
        ? chatState.conversations
        : chatState.conversations
              .where((c) => c.title.toLowerCase().contains(_query))
              .toList();
    final groups = _groupByRecency(filtered);

    final width = MediaQuery.of(context).size.width;
    final drawerWidth = (width * 0.8).clamp(280.0, 400.0);

    return Drawer(
      backgroundColor: context.colors.surface,
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: AppSpacing.lg),
            _NewChatButton(
              onTap: () {
                notifier.startNewConversation();
                ref.read(mainTabProvider.notifier).state = chatTabIndex;
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _ConversationSearchField(controller: _searchController),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (hasAnyConversations)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Recent',
                  style: AppTypography.sectionHeading(context),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: !hasAnyConversations
                  ? const _EmptyConversations(
                      message: 'Your recent conversations will show up here.',
                    )
                  : groups.isEmpty
                  ? const _EmptyConversations(
                      message: 'No conversations match your search.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final item = groups[index];
                        if (item is _GroupHeader) {
                          return _GroupHeaderLabel(label: item.label);
                        }
                        final conversation = (item as _GroupItem).conversation;
                        return _ConversationTile(
                          conversation: conversation,
                          isActive:
                              conversation.id ==
                              chatState.currentConversationId,
                          onTap: () async {
                            Navigator.of(context).pop();
                            ref.read(mainTabProvider.notifier).state =
                                chatTabIndex;
                            await notifier.openConversation(conversation.id);
                          },
                          onDelete: () =>
                              _handleDelete(context, notifier, conversation),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: context.colors.borderSubtle),
            // _SettingsRow(onTap: () => _openProfile(context, ref)),
            _DrawerProfileFooter(onTap: () => _openProfile(context, ref)),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    ref.read(mainTabProvider.notifier).state = profileTabIndex;
  }
}

/// A group header ("Today"/"Yesterday"/"Earlier") or a conversation row,
/// flattened into one list so [ListView.builder] can lazily build both —
/// simpler than a nested `SliverList` per group for what's normally a
/// short list.
sealed class _RecencyListItem {}

class _GroupHeader extends _RecencyListItem {
  _GroupHeader(this.label);
  final String label;
}

class _GroupItem extends _RecencyListItem {
  _GroupItem(this.conversation);
  final Conversation conversation;
}

/// Buckets [conversations] (already sorted newest-first) into Today /
/// Yesterday / Earlier groups, reusing [DateFormatting.toRelativeConversationDate]
/// (rather than re-deriving day-difference math here) purely to classify
/// which bucket each one falls into.
List<_RecencyListItem> _groupByRecency(List<Conversation> conversations) {
  final items = <_RecencyListItem>[];
  String? currentGroup;
  for (final conversation in conversations) {
    final relative = conversation.updatedAt.toRelativeConversationDate();
    final group = switch (relative) {
      'Today' => 'Today',
      'Yesterday' => 'Yesterday',
      _ => 'Earlier',
    };
    if (group != currentGroup) {
      items.add(_GroupHeader(group));
      currentGroup = group;
    }
    items.add(_GroupItem(conversation));
  }
  return items;
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FinAssistLogo(size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fin',
                        style: AppTypography.greeting(
                          context,
                        ).copyWith(color: context.colors.textPrimary),
                      ),
                      TextSpan(
                        text: 'Assist',
                        style: AppTypography.greeting(
                          context,
                        ).copyWith(color: context.colors.accentStrong),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Semantics(
              //   button: true,
              //   label: 'Close menu',
              //   child: InkWell(
              //     customBorder: const CircleBorder(),
              //     onTap: onClose,
              //     child: const Padding(
              //       padding: EdgeInsets.all(AppSpacing.sm),
              //       child: Icon(
              //         Icons.close_rounded,
              //         color: context.colors.textSecondary,
              //         size: 22,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
          Text(
            'Your AI partner for a healthier financial life.',
            style: AppTypography.caption(
              context,
            ).copyWith(color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: context.colors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: context.colors.accentStrong,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'New chat',
                  style: AppTypography.bodyMedium(context).copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationSearchField extends StatelessWidget {
  const _ConversationSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Search conversations',
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.borderSubtle),
        ),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.body(
            context,
          ).copyWith(color: context.colors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'Search conversations...',
            hintStyle: AppTypography.body(
              context,
            ).copyWith(color: context.colors.textMuted),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.colors.textMuted,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          ),
        ),
      ),
    );
  }
}

class _GroupHeaderLabel extends StatelessWidget {
  const _GroupHeaderLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.caption(context).copyWith(
          color: context.colors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final relative = conversation.updatedAt.toRelativeConversationDate();
    final timeLabel = relative == 'Today'
        ? conversation.updatedAt.toTimeOfDay()
        : relative;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Semantics(
        button: true,
        label: conversation.title,
        selected: isActive,
        child: Material(
          color: isActive
              ? context.colors.surfaceHighlight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isActive
                        ? context.colors.accentStrong
                        : context.colors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(
                        context,
                      ).copyWith(color: context.colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    timeLabel,
                    style: AppTypography.caption(
                      context,
                    ).copyWith(color: context.colors.textMuted),
                  ),
                  Semantics(
                    button: true,
                    label: 'Conversation options',
                    child: PopupMenuButton<_ConversationAction>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: context.colors.textMuted,
                        size: 18,
                      ),
                      color: context.colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(color: context.colors.border),
                      ),
                      onSelected: (action) {
                        if (action == _ConversationAction.delete) onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _ConversationAction.delete,
                          child: Text(
                            'Delete',
                            style: AppTypography.body(
                              context,
                            ).copyWith(color: context.colors.negative),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ConversationAction { delete }

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        message,
        style: AppTypography.body(
          context,
        ).copyWith(color: context.colors.textMuted),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Settings',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: context.colors.textSecondary,
                size: 19,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Settings',
                  style: AppTypography.bodyMedium(
                    context,
                  ).copyWith(color: context.colors.textSecondary),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileFooter extends ConsumerWidget {
  const _DrawerProfileFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(currentUserIdentityProvider);
    final pictureUrl = ref.watch(
      profileControllerProvider.select((s) => s.profile?.profilePictureUrl),
    );
    final name = '${identity.firstName} ${identity.lastName}'.trim();
    final subtitle = identity.username.isNotEmpty
        ? '@${identity.username}'
        : identity.email;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Semantics(
        button: true,
        label: 'Open profile',
        child: Material(
          color: context.colors.surfaceHighlight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  UserAvatar(
                    imageUrl: pictureUrl,
                    size: 38,
                    onImageError: pictureUrl == null
                        ? null
                        : () => WidgetsBinding.instance.addPostFrameCallback(
                            (_) => ref
                                .read(profileControllerProvider.notifier)
                                .refreshIfPictureUrlStale(pictureUrl),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'FinAssist user' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(context).copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              context,
                            ).copyWith(color: context.colors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
