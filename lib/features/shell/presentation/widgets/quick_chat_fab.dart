import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/finassist_logo.dart';
import '../providers/shell_providers.dart';

/// A floating shortcut back to Chat, shown on every non-Chat tab of
/// [MainShellScreen]. Switches [mainTabProvider] to the existing Chat tab
/// rather than pushing a new route, so there's never a second Chat screen
/// on the navigation stack.
///
/// Deliberately branded with the FinAssist mark rather than a chat-bubble
/// icon — the bottom nav's Chat tab already owns that "chat destination"
/// identity; this is a distinct "FinAssist AI is one tap away" shortcut,
/// not a second chat button.
class QuickChatFab extends ConsumerStatefulWidget {
  const QuickChatFab({super.key});

  @override
  ConsumerState<QuickChatFab> createState() => _QuickChatFabState();
}

class _QuickChatFabState extends ConsumerState<QuickChatFab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'FinAssist AI — return to chat',
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.accentSoft,
            border: Border.all(
              color: context.colors.accent.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () =>
                  ref.read(mainTabProvider.notifier).state = chatTabIndex,
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              customBorder: const CircleBorder(),
              child: const Center(child: FinAssistLogo(size: 28)),
            ),
          ),
        ),
      ),
    );
  }
}
