import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/ai_avatar.dart';
import '../../../../shared/widgets/fade_slide_in.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/quick_action.dart';
import '../providers/chat_controller.dart';
import '../providers/chat_state.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/conversation_load_banner.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/scroll_to_latest_button.dart';
import '../widgets/statement_context_bar.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  /// Shows the "scroll to latest" affordance once new content has arrived
  /// below what's currently in view — either because the user scrolled
  /// away, or because a response grew past the bottom of the viewport
  /// while they stayed anchored on their question.
  bool _hasNewMessageBelow = false;

  /// Guards against queuing more than one pending bottom-jump per frame.
  bool _jumpScheduled = false;

  /// A `GlobalKey` per message, so a just-sent user message can be
  /// measured and positioned precisely (see `_positionMessageNearTop`)
  /// instead of guessing an offset. Cleared whenever the active
  /// conversation changes so stale keys never linger.
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _positionOnScreenEntry(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Positions the view at the latest message the moment this screen
  /// becomes active. Covers returning to an already-loaded conversation
  /// (e.g. Dashboard -> FinAssist) — `chatControllerProvider` is a single,
  /// screen-independent instance, so if it was already `loaded` before
  /// this screen mounted, no `ChatState` change occurs for
  /// `_handleChatStateChange` to react to, and the fresh `ScrollController`
  /// this new screen instance created would otherwise sit wherever it
  /// happened to start (including a stale offset Flutter's own
  /// `PageStorage` may try to restore). A conversation still mid-load at
  /// mount time is instead handled by the `justLoaded` branch of
  /// `_handleChatStateChange` once it actually finishes — this runs once,
  /// after the first real layout, never on a mere rebuild.
  void _positionOnScreenEntry() {
    if (!mounted) return;
    final chatState = ref.read(chatControllerProvider);
    if (chatState.conversationStatus == ConversationLoadStatus.loaded &&
        chatState.messages.isNotEmpty) {
      _jumpToBottom();
    }
  }

  GlobalKey _keyFor(String messageId) {
    return _messageKeys.putIfAbsent(messageId, GlobalKey.new);
  }

  /// Checked fresh whenever we need it (a message arrives, or the user
  /// physically drags) rather than cached — our own scroll calls also move
  /// the scroll position, and caching would let that self-trigger a false
  /// "user scrolled away" reading that never recovers.
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - 80;
  }

  /// Only reacts to genuine user drags (via [ScrollUpdateNotification]'s
  /// `dragDetails`) — ignores notifications produced by our own
  /// programmatic scrolling. A drag that lands the user back near the
  /// bottom clears the "new content below" affordance; a drag away from it
  /// never triggers any scroll of our own — the user's position is never
  /// fought.
  bool _handleUserScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _isNearBottom() &&
        _hasNewMessageBelow) {
      setState(() => _hasNewMessageBelow = false);
    }
    return false;
  }

  /// Instantly (no animation) snaps to the current bottom of the list —
  /// used for entering/restoring a conversation, so there's no visible
  /// scroll motion, just a stable final position at the latest message.
  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= position.pixels) return;
    _scrollController.jumpTo(position.maxScrollExtent);
  }

  void _scheduleJumpToBottom() {
    if (_jumpScheduled) return;
    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpScheduled = false;
      _jumpToBottom();
    });
  }

  /// A single, deliberate positioning for a just-sent message: scrolls so
  /// its top edge lands at the top of the viewport, leaving the rest of
  /// the viewport free for the assistant's response to grow into — the
  /// same "your message settles near the top, the reply grows beneath it"
  /// behavior professional chat apps use, instead of shoving the new
  /// message to the very bottom edge where the reply has nowhere to go
  /// but to keep shoving it further up.
  void _positionMessageNearTop(String messageId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _messageKeys[messageId]?.currentContext;
      if (targetContext == null) {
        _jumpToBottom();
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleAttach() {
    FocusScope.of(context).unfocus();
    ref.read(chatControllerProvider.notifier).pickAndUploadStatement();
  }

  void _handleSendMessage(String text) {
    ref.read(chatControllerProvider.notifier).sendMessage(text);
  }

  void _handleQuickAction(QuickAction action) {
    FocusScope.of(context).unfocus();
    if (action.triggersUpload) {
      _handleAttach();
      return;
    }
    _handleSendMessage(action.prompt);
  }

  /// Interprets each `ChatState` change into exactly one of: a fresh
  /// conversation just finished loading, the thread just emptied out, a
  /// new user message was just sent, or the assistant's reply is
  /// growing/settling — and reacts with exactly one, deterministic action
  /// per case. No arbitrary delays: every trigger here corresponds to a
  /// real, observable state transition from `ChatController`.
  void _handleChatStateChange(ChatState? previous, ChatState next) {
    final justLoaded =
        previous?.conversationStatus != ConversationLoadStatus.loaded &&
        next.conversationStatus == ConversationLoadStatus.loaded;

    if (justLoaded) {
      // A conversation (bootstrap restore, drawer switch, or a fresh
      // reload after an error) just finished loading — position at the
      // latest message once, instantly, with no visible scroll motion.
      _messageKeys.clear();
      if (_hasNewMessageBelow) setState(() => _hasNewMessageBelow = false);
      if (next.messages.isNotEmpty) _scheduleJumpToBottom();
      return;
    }

    if (next.messages.isEmpty) {
      if (previous != null && previous.messages.isNotEmpty) {
        // Started a new conversation / thread reset — nothing to scroll,
        // just reset tracking so stale keys/flags don't leak into it.
        _messageKeys.clear();
        if (_hasNewMessageBelow) setState(() => _hasNewMessageBelow = false);
      }
      return;
    }

    final lastMessage = next.messages.last;
    final previousLastId = (previous != null && previous.messages.isNotEmpty)
        ? previous.messages.last.id
        : null;
    final isNewUserMessage =
        lastMessage.role == ChatMessageRole.user &&
        lastMessage.id != previousLastId;

    if (isNewUserMessage) {
      // Anchor this turn: position the just-sent message near the top of
      // the viewport, once, and leave the scroll offset alone from then
      // on — the reply renders directly beneath it and grows downward
      // without ever being followed, which is exactly what stops the
      // question from being pushed back upward as the reply grows.
      if (_hasNewMessageBelow) setState(() => _hasNewMessageBelow = false);
      _positionMessageNearTop(lastMessage.id);
      return;
    }

    final isStreaming = next.streamingMessageId != null;
    final messageAdded =
        (previous?.messages.length ?? 0) != next.messages.length;
    if (!isStreaming && !messageAdded) return;

    // Deliberately no auto-scroll here while a response grows — the
    // viewport stays exactly where `_positionMessageNearTop` (or the
    // user) left it. If that leaves new content below the fold, surface
    // the existing "scroll to latest" affordance instead of forcing the
    // view down; tapping it is the only thing that ever moves the
    // viewport once generation is underway.
    if (!_isNearBottom() && !_hasNewMessageBelow) {
      setState(() => _hasNewMessageBelow = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    ref.listen(chatControllerProvider, _handleChatStateChange);

    // No Scaffold `appBar:` here on purpose — see ChatAppBar's doc comment.
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const ChatAppBar(),
            Expanded(child: _buildBody(chatState)),
            if (chatState.conversationStatus == ConversationLoadStatus.loaded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (chatState.messages.isNotEmpty) ...[
                      QuickActionsRow(
                        actions: quickActionsFor(
                          hasFinancialData: chatState.hasFinancialData,
                        ),
                        onSelect: _handleQuickAction,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    ChatComposer(
                      onSend: _handleSendMessage,
                      onAttach: _handleAttach,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The center area beneath the header: whichever of loading / error /
  /// empty / message-list state currently applies. Every one of these is
  /// an intentional, on-brand state — never a blank screen.
  Widget _buildBody(ChatState chatState) {
    switch (chatState.conversationStatus) {
      case ConversationLoadStatus.loading:
        return const _ConversationLoadingState();
      case ConversationLoadStatus.error:
        return ConversationLoadBanner(
          message:
              chatState.conversationError ??
              "FinAssist couldn't connect right now.",
          onRetry: () => ref.read(chatControllerProvider.notifier).retryLoad(),
        );
      case ConversationLoadStatus.loaded:
        if (chatState.messages.isEmpty) {
          return EmptyChatState(onSuggestionSelected: _handleSendMessage);
        }
        return _buildMessageList(chatState);
    }
  }

  Widget _buildMessageList(ChatState chatState) {
    final hasStatementContext =
        chatState.hasFinancialData &&
        chatState.statementFileName != null &&
        chatState.statementPeriodStart != null &&
        chatState.statementPeriodEnd != null;

    final lastAssistantIndex = chatState.messages.lastIndexWhere(
      (m) => m.role == ChatMessageRole.assistant,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: _handleUserScroll,
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              if (hasStatementContext) ...[
                FadeSlideIn(
                  key: ValueKey('statement-${chatState.statementFileName}'),
                  child: StatementContextBar(
                    fileName: chatState.statementFileName!,
                    periodLabel: formatDateRange(
                      chatState.statementPeriodStart!,
                      chatState.statementPeriodEnd!,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              for (var i = 0; i < chatState.messages.length; i++) ...[
                KeyedSubtree(
                  key: _keyFor(chatState.messages[i].id),
                  child: FadeSlideIn(
                    key: ValueKey(chatState.messages[i].id),
                    child: ChatBubble(
                      message: chatState.messages[i],
                      onFollowUpSelected: _handleSendMessage,
                      showAssistantActions:
                          _isSubstantiveAssistantMessage(
                            chatState.messages[i],
                          ) &&
                          i == lastAssistantIndex &&
                          chatState.streamingMessageId !=
                              chatState.messages[i].id,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (chatState.isAssistantTyping)
                TypingIndicator(statusLabel: chatState.typingLabel),
            ],
          ),
          if (_hasNewMessageBelow)
            Positioned(
              bottom: AppSpacing.sm,
              left: 0,
              right: 0,
              child: Center(
                child: ScrollToLatestButton(
                  onTap: () {
                    setState(() => _hasNewMessageBelow = false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_scrollController.hasClients) return;
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSubstantiveAssistantMessage(ChatMessage message) {
    return message.role == ChatMessageRole.assistant &&
        (message.messageType == ChatMessageType.text ||
            message.messageType == ChatMessageType.categoryBreakdown ||
            message.messageType == ChatMessageType.recurringPayments);
  }
}

/// A stable, centered, on-brand loading state shown while a conversation
/// is being restored or switched — replaces the old bare spinner so
/// nothing appears to "pop" into place once loading finishes; the chat
/// content stays hidden entirely until it's fully ready to render in its
/// final position.
class _ConversationLoadingState extends StatelessWidget {
  const _ConversationLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AIAvatar(size: 40),
          const SizedBox(height: AppSpacing.lg),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Loading conversation...', style: AppTypography.body),
        ],
      ),
    );
  }
}
