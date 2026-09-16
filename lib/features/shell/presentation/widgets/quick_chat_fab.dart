import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/shell_providers.dart';

/// A small floating shortcut back to Chat, shown on every non-Chat tab of
/// [MainShellScreen]. Switches [mainTabProvider] to the existing Chat tab
/// rather than pushing a new route, so there's never a second Chat screen
/// on the navigation stack.
class QuickChatFab extends ConsumerWidget {
  const QuickChatFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Return to chat',
      child: FloatingActionButton.small(
        heroTag: 'quickChatFab',
        backgroundColor: AppColors.accentDeep,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () =>
            ref.read(mainTabProvider.notifier).state = chatTabIndex,
        child: const Icon(Icons.chat_bubble_rounded, size: 20),
      ),
    );
  }
}
