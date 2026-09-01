import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/ai_avatar.dart';
import '../providers/chat_controller.dart';

/// The chat screen's header: a menu icon that opens the conversations
/// drawer, the FinAssist identity, a home icon that returns to the
/// existing Dashboard, and a "+" that starts a fresh conversation — a
/// workspace, not a single session with an "end" action.
///
/// The home icon is deliberately the *only* control here that navigates
/// to Dashboard — the title isn't tappable, the menu only opens the
/// drawer, and "+" only starts a new conversation.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            semanticLabel: 'Open menu',
            onTap: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: AppSpacing.xs),
          const AIAvatar(size: 30),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'FinAssist AI',
              style: AppTypography.screenTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _HeaderIconButton(
            icon: Icons.home_rounded,
            semanticLabel: 'Go to Dashboard',
            onTap: () => _goToDashboard(context),
          ),
          _HeaderIconButton(
            icon: Icons.add_rounded,
            semanticLabel: 'New conversation',
            onTap: () => ref
                .read(chatControllerProvider.notifier)
                .startNewConversation(),
          ),
        ],
      ),
    );
  }

  /// Chat is always reached by pushing on top of the existing Dashboard
  /// route, so returning to it is just popping back to that instance —
  /// never pushing a second Dashboard/route. The fallback only matters if
  /// this screen were ever somehow the root of the stack.
  void _goToDashboard(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
