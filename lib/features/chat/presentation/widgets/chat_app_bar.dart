import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../shell/presentation/widgets/main_header_bar.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_state.dart';

/// Chat's header: a menu icon that opens the conversations drawer, the
/// FinAssist identity with a contextual subtitle, and an avatar that jumps
/// to Profile. Deliberately has no back arrow and no "go to Dashboard"
/// icon — Chat is FinAssist's root/landing destination, not a screen
/// something else navigated into. Starting a new conversation lives
/// solely in the drawer's "+ New chat" (see `ChatDrawer`) — there is
/// exactly one way to do it.
///
/// Deliberately not a Scaffold `appBar:` — a custom [PreferredSizeWidget]
/// placed there doesn't get the automatic top-safe-area handling built-in
/// `AppBar` gets, and worse, Scaffold assumes the app bar already consumed
/// it and strips that inset from the body's `MediaQuery`. Living inside the
/// body's own `SafeArea` instead sidesteps that mismatch entirely.
class ChatAppBar extends ConsumerWidget {
  const ChatAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    return MainHeaderBar(subtitle: _StatusSubtitle(chatState: chatState));
  }
}

/// "Your financial AI companion" before any conversation exists, or a
/// small derived online/offline indicator once one is underway — derived
/// from `ChatState.conversationStatus`, not a separate polling subsystem.
class _StatusSubtitle extends StatelessWidget {
  const _StatusSubtitle({required this.chatState});

  final ChatState chatState;

  @override
  Widget build(BuildContext context) {
    if (chatState.messages.isEmpty) return const BrandTagline();

    final isOffline =
        chatState.conversationStatus == ConversationLoadStatus.error;
    final color = isOffline ? AppColors.negative : AppColors.accentStrong;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isOffline ? 'Offline' : 'Online',
          style: AppTypography.caption.copyWith(color: color),
        ),
      ],
    );
  }
}
