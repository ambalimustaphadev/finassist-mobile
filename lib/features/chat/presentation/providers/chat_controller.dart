import 'dart:async';

import 'package:finassist/features/chat/data/repositories/api_chat_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/services/statement_file_picker_service.dart';
import '../../../../shared/models/uploaded_file_attachment.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/local/local_conversation_store.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_state.dart';

/// Swap this provider's override for tests (e.g. `MockChatRepository`); the
/// chat screen itself never changes.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ApiChatRepository(baseUrl: apiBaseUrl);
});

/// Swap for a fake in tests, or leave as-is in production — it's the only
/// thing in the chat feature that talks to a platform channel.
final statementFilePickerServiceProvider = Provider<StatementFilePickerService>(
  (ref) {
    return FilePickerStatementService();
  },
);

/// Local (on-device) cache of conversations/messages — see
/// `LocalConversationStore`'s doc comment for how it relates to the
/// backend, which is the source of truth whenever it's reachable.
final localConversationStoreProvider = Provider<LocalConversationStore>((ref) {
  return LocalConversationStore();
});

/// Rebuilt whenever the authenticated user changes, so one user's
/// conversations/greeting never bleed into another's session — both the
/// user's id (for scoping local storage) and first name (for the empty
/// state's greeting) come from here rather than a separate user store.
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    final userId =
        ref.watch(authControllerProvider.select((state) => state.user?.id)) ??
        'guest';
    return ChatController(
      ref.watch(chatRepositoryProvider),
      ref.watch(statementFilePickerServiceProvider),
      ref.watch(localConversationStoreProvider),
      userId,
    );
  },
);

/// How long a just-attached file stays cancelable before analysis begins
/// automatically. Long enough to comfortably tap "×", short enough that the
/// conversation still feels responsive.
const _attachmentConfirmWindow = Duration(milliseconds: 900);

/// How long to pause between each progressively-revealed chunk of an
/// assistant response (see `ChatController._streamAssistantReply`). Purely
/// a Flutter presentation effect — by the time this pacing starts, the
/// complete response has already arrived from the backend in one HTTP
/// round trip, so nothing here waits on the network. When real backend
/// streaming lands, deltas will already arrive spaced out by the network
/// itself and this same reveal loop keeps working unchanged.
const _revealTickInterval = Duration(milliseconds: 20);

/// Takes the next chunk to reveal off the front of [pending]: a whole word
/// (plus its trailing whitespace) when the next word boundary is close by,
/// or a short fixed-size slice otherwise (e.g. one very long unbroken
/// token, such as a long number) so the reveal never stalls waiting for a
/// boundary that isn't coming.
String _takeNextRevealChunk(String pending) {
  final match = RegExp(r'^\S+\s*').firstMatch(pending);
  if (match != null && match.end <= 24) {
    return pending.substring(0, match.end);
  }
  final take = pending.length < 8 ? pending.length : 8;
  return pending.substring(0, take);
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repository, this._filePicker, this._store, this._userId)
    : super(const ChatState()) {
    _bootstrap();
  }

  final ChatRepository _repository;
  final StatementFilePickerService _filePicker;
  final LocalConversationStore _store;
  final String _userId;

  /// Identifies the currently in-flight progressive-reveal animation, if
  /// any. Each call to [_streamAssistantReply] mints a fresh token and
  /// checks it before every `state` mutation; replacing it (or nulling it)
  /// is how any other part of the controller cancels a stale animation —
  /// starting a new message, switching/creating a conversation, or
  /// disposing the controller.
  Object? _activeRevealToken;

  /// Force-completes the currently active reveal (jumps straight to the
  /// full, final text and persists it) — set by [_streamAssistantReply]
  /// while it's running, and cleared once it finishes on its own.
  void Function()? _pendingRevealFlush;

  /// Cancels any in-flight reveal animation. If [flush] is true (the
  /// default) and a response has already fully arrived, it's completed to
  /// its final text and persisted immediately rather than left
  /// half-revealed — used when a new message/conversation needs the
  /// previous response to be "done" first. Disposal uses `flush: false`
  /// since completing would mean writing to `state` after this notifier
  /// is no longer mounted.
  void _cancelActiveReveal({bool flush = true}) {
    final pendingFlush = _pendingRevealFlush;
    _pendingRevealFlush = null;
    _activeRevealToken = null;
    if (flush) pendingFlush?.call();
  }

  @override
  void dispose() {
    _cancelActiveReveal(flush: false);
    super.dispose();
  }

  /// Restores the most recently active conversation on launch, so the user
  /// never loses their latest thread just because the app was closed. The
  /// backend (`GET /api/conversations`) is the source of truth; the local
  /// cache is only consulted if that call itself fails (no connection). A
  /// user with no conversations at all lands on the empty state — nothing
  /// is created until they actually send a message.
  Future<void> _bootstrap() async {
    state = state.copyWith(conversationStatus: ConversationLoadStatus.loading);
    try {
      final conversations = await _repository.getConversations();
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      unawaited(_store.upsertConversationMetadata(_userId, conversations));

      if (conversations.isEmpty) {
        state = state.copyWith(
          conversations: conversations,
          conversationStatus: ConversationLoadStatus.loaded,
          clearCurrentConversationId: true,
          messages: const [],
        );
        return;
      }

      final latest = conversations.first;
      final detail = await _repository.getConversation(latest.id);
      unawaited(
        _store.saveConversation(_userId, detail.conversation, detail.messages),
      );
      state = state.copyWith(
        conversations: conversations,
        currentConversationId: detail.conversation.id,
        messages: detail.messages,
        conversationStatus: ConversationLoadStatus.loaded,
      );
    } on ChatUnauthorizedException {
      state = state.copyWith(
        conversationStatus: ConversationLoadStatus.error,
        conversationError: 'Your session has expired. Please log in again.',
      );
    } catch (_) {
      final cached = await _restoreFromCache();
      if (cached != null) {
        state = cached;
        return;
      }
      state = state.copyWith(
        conversationStatus: ConversationLoadStatus.error,
        conversationError: "FinAssist couldn't connect right now.",
      );
    }
  }

  /// Offline fallback for [_bootstrap] — used only when the backend call
  /// itself fails (e.g. no connection), never when it succeeds but returns
  /// an empty list.
  Future<ChatState?> _restoreFromCache() async {
    final cached = await _store.loadConversations(_userId);
    if (cached.isEmpty) return null;

    cached.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final latest = cached.first;
    final messages = await _store.loadMessages(_userId, latest.id);
    return state.copyWith(
      conversations: cached,
      currentConversationId: latest.id,
      messages: messages,
      conversationStatus: ConversationLoadStatus.loaded,
    );
  }

  Future<void> retryLoad() => _bootstrap();

  /// Clears the active conversation's financial-data context — called when
  /// the user deletes their stored financial data from Profile, so the
  /// assistant doesn't keep referencing a statement that no longer exists.
  /// Only affects in-memory/session state; it doesn't touch messages
  /// already in the conversation.
  void clearFinancialDataContext() {
    if (!state.hasFinancialData) return;
    state = state.copyWith(
      hasFinancialData: false,
      clearStatementContext: true,
    );
  }

  /// Starts a fresh thread: clears the current messages and shows the
  /// empty state. No backend call happens here — the conversation is only
  /// created (via `POST /api/conversations`) once the user actually sends
  /// their first message, so an unsent "New conversation" never clutters
  /// the drawer or the backend.
  void startNewConversation() {
    _cancelActiveReveal();
    state = ChatState(
      conversations: state.conversations,
      conversationStatus: ConversationLoadStatus.loaded,
    );
  }

  /// Loads a previous conversation's messages from the backend and makes
  /// it the active one. Never creates a new conversation — reopening
  /// always continues the existing thread.
  Future<void> openConversation(String conversationId) async {
    if (conversationId == state.currentConversationId) return;

    _cancelActiveReveal();
    state = state.copyWith(
      currentConversationId: conversationId,
      conversationStatus: ConversationLoadStatus.loading,
      messages: const [],
      hasFinancialData: false,
      clearTypingLabel: true,
      clearStreamingMessageId: true,
      clearPendingAttachment: true,
      clearLastFailedAttachment: true,
    );
    try {
      final detail = await _repository.getConversation(conversationId);
      unawaited(
        _store.saveConversation(_userId, detail.conversation, detail.messages),
      );
      state = state.copyWith(
        conversations: _touchConversation(
          conversationId,
          updatedAt: detail.conversation.updatedAt,
        ),
        messages: detail.messages,
        conversationStatus: ConversationLoadStatus.loaded,
      );
    } on ChatUnauthorizedException {
      state = state.copyWith(
        conversationStatus: ConversationLoadStatus.error,
        conversationError: 'Your session has expired. Please log in again.',
      );
    } catch (_) {
      final cachedMessages = await _store.loadMessages(_userId, conversationId);
      if (cachedMessages.isNotEmpty) {
        state = state.copyWith(
          messages: cachedMessages,
          conversationStatus: ConversationLoadStatus.loaded,
        );
        return;
      }
      state = state.copyWith(
        conversationStatus: ConversationLoadStatus.error,
        conversationError: 'Could not load this conversation.',
      );
    }
  }

  /// Deletes a conversation on the backend and, if that succeeds, removes
  /// it from local state/cache too. Left untouched on failure — there's
  /// nothing safe to reconcile client-side if the backend call didn't go
  /// through.
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
    } catch (_) {
      return;
    }

    final wasCurrent = state.currentConversationId == conversationId;
    // If the deleted conversation was the one actively (re)generating a
    // response, there's nothing left to reveal it into — drop it rather
    // than flush it to a conversation that no longer exists.
    if (wasCurrent) _cancelActiveReveal(flush: false);
    state = state.copyWith(
      conversations: state.conversations
          .where((c) => c.id != conversationId)
          .toList(),
      currentConversationId: wasCurrent ? null : state.currentConversationId,
      clearCurrentConversationId: wasCurrent,
      messages: wasCurrent ? const [] : state.messages,
    );
    unawaited(_store.deleteConversation(_userId, conversationId));
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatMessageRole.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isAssistantTyping: true,
      clearTypingLabel: true,
      clearStreamingMessageId: true,
    );

    await _dispatchUserMessage(userMessage);
  }

  /// Re-sends a message that previously failed, in place. Goes through the
  /// same path as [sendMessage] so a message that failed *before* a
  /// conversation existed yet (e.g. the very first message, if
  /// `createConversation` itself failed) can still be retried.
  Future<void> retrySend(String failedMessageId) async {
    final matches = state.messages.where((m) => m.id == failedMessageId);
    if (matches.isEmpty) return;
    final message = matches.first;

    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == failedMessageId) m.copyWith(sendFailed: false) else m,
      ],
      isAssistantTyping: true,
      clearTypingLabel: true,
    );

    await _dispatchUserMessage(message);
  }

  /// Ensures a real backend conversation exists (creating one via
  /// `POST /api/conversations` on first send — never a fake local id),
  /// persists the message locally, then streams the assistant's reply.
  Future<void> _dispatchUserMessage(ChatMessage userMessage) async {
    // A previous response's reveal animation, if still running, must
    // finish (not be left half-typed) before this new one starts.
    _cancelActiveReveal();

    final String conversationId;
    try {
      conversationId = await _ensureConversation(
        seedTitleFrom: userMessage.text,
      );
    } catch (_) {
      state = state.copyWith(isAssistantTyping: false);
      _markSendFailed(userMessage.id);
      return;
    }

    _persist(conversationId, state.messages);

    await _streamAssistantReply(
      conversationId: conversationId,
      userMessage: userMessage.text,
      onFailure: () => _markSendFailed(userMessage.id),
    );
  }

  /// Returns the current conversation's id, creating one on the backend
  /// first if this is the first message in a fresh thread.
  Future<String> _ensureConversation({required String seedTitleFrom}) async {
    final existing = state.currentConversationId;
    if (existing != null) return existing;

    final title = _repository.suggestTitle(seedTitleFrom);
    final conversation = await _repository.createConversation(title);
    state = state.copyWith(
      currentConversationId: conversation.id,
      conversations: [conversation, ...state.conversations],
    );
    return conversation.id;
  }

  /// Replaces [messageId] (an assistant message) with a freshly generated
  /// response to whichever user message prompted it.
  Future<void> regenerateResponse(String messageId) async {
    final conversationId = state.currentConversationId;
    if (conversationId == null) return;

    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index <= 0) return;

    final precedingUser = state.messages
        .sublist(0, index)
        .lastWhere(
          (m) => m.role == ChatMessageRole.user,
          orElse: () => state.messages[index],
        );
    if (precedingUser.id == messageId) return;

    _cancelActiveReveal();
    final messagesWithoutOld = [...state.messages]..removeAt(index);
    state = state.copyWith(
      messages: messagesWithoutOld,
      isAssistantTyping: true,
      clearTypingLabel: true,
      clearStreamingMessageId: true,
    );

    await _streamAssistantReply(
      conversationId: conversationId,
      userMessage: precedingUser.text,
    );
  }

  /// Shared by [_dispatchUserMessage] and [regenerateResponse]: appends a
  /// streamed assistant reply to whichever conversation is current, then
  /// progressively reveals its text — a Flutter-only presentation effect
  /// layered on top of the existing delta/done stream (see
  /// [_takeNextRevealChunk]'s doc comment). Today's backend answers in one
  /// HTTP round trip, so by the time reveal pacing starts the full text is
  /// already in hand; when the backend streams real deltas later, each one
  /// simply gets queued and revealed the same way, so this code doesn't
  /// need to change.
  Future<void> _streamAssistantReply({
    required String conversationId,
    required String userMessage,
    VoidCallback? onFailure,
  }) async {
    final assistantId = 'ai-${DateTime.now().microsecondsSinceEpoch}';
    final revealToken = Object();
    _activeRevealToken = revealToken;

    var placeholderInserted = false;
    var revealedText = '';
    var pendingText = '';
    var streamFinished = false;
    var draining = false;
    ChatMessage? finalComplete;

    bool isActive() => _activeRevealToken == revealToken;

    void insertPlaceholderIfNeeded() {
      if (placeholderInserted) return;
      placeholderInserted = true;
      final placeholder = ChatMessage(
        id: assistantId,
        role: ChatMessageRole.assistant,
        text: '',
        timestamp: DateTime.now(),
        conversationId: conversationId,
      );
      // The bubble appears immediately, empty — isAssistantTyping (the
      // three-dot indicator) turns off here in favor of the bubble's own
      // text growing, and streamingMessageId keeps it (and the existing
      // scroll-to-bottom listener in ChatScreen) marked as in-progress
      // until the reveal finishes below.
      state = state.copyWith(
        messages: [...state.messages, placeholder],
        isAssistantTyping: false,
        streamingMessageId: assistantId,
      );
    }

    // Jumps straight to the complete, final message and persists it —
    // called either once the reveal naturally finishes, or immediately by
    // a forced [_cancelActiveReveal] elsewhere in the controller. Doesn't
    // check [isActive] itself: a forced flush intentionally runs after the
    // token's already been cleared, and both call sites already guard
    // against calling this more than once.
    void finalize() {
      final complete = finalComplete;
      if (complete == null) return;
      final finalMessage = ChatMessage(
        id: assistantId,
        role: ChatMessageRole.assistant,
        text: complete.text,
        timestamp: DateTime.now(),
        conversationId: conversationId,
        messageType: complete.messageType,
        highlights: complete.highlights,
        categoryBreakdown: complete.categoryBreakdown,
        recurringPayments: complete.recurringPayments,
        followUpSuggestions: complete.followUpSuggestions,
        usedFinancialData: complete.usedFinancialData,
      );
      final messages = _replaceOrAppend(
        state.messages,
        assistantId,
        finalMessage,
      );
      state = state.copyWith(
        messages: messages,
        isAssistantTyping: false,
        clearStreamingMessageId: true,
        conversations: _touchConversation(conversationId),
      );
      _persist(conversationId, messages);
      if (_activeRevealToken == revealToken) _activeRevealToken = null;
      _pendingRevealFlush = null;
    }

    _pendingRevealFlush = finalize;

    // Drains [pendingText] into the visible message a small chunk at a
    // time, pausing [_revealTickInterval] between chunks. Re-entrant-safe
    // ([draining] guards it) so it can be kicked off again as more text
    // arrives without starting a second, overlapping loop.
    Future<void> drain() async {
      if (draining) return;
      draining = true;
      while (pendingText.isNotEmpty) {
        if (!isActive()) {
          draining = false;
          return;
        }
        final chunk = _takeNextRevealChunk(pendingText);
        revealedText += chunk;
        pendingText = pendingText.substring(chunk.length);
        state = state.copyWith(
          messages: [
            for (final m in state.messages)
              if (m.id == assistantId) m.copyWith(text: revealedText) else m,
          ],
        );
        if (pendingText.isNotEmpty) {
          await Future<void>.delayed(_revealTickInterval);
        }
      }
      draining = false;
      if (!isActive()) return;
      if (streamFinished) finalize();
    }

    try {
      await for (final chunk in _repository.sendMessage(
        conversationId,
        userMessage,
      )) {
        if (!isActive()) return;

        if (chunk.isDone) {
          finalComplete = chunk.message;
          streamFinished = true;
          insertPlaceholderIfNeeded();
          if (pendingText.isEmpty && !draining) {
            finalize();
          } else {
            unawaited(drain());
          }
          break;
        }

        insertPlaceholderIfNeeded();
        pendingText += chunk.textDelta;
        unawaited(drain());
      }
    } catch (_) {
      if (_activeRevealToken == revealToken) {
        _activeRevealToken = null;
        _pendingRevealFlush = null;
      }
      final messages = placeholderInserted
          ? state.messages.where((m) => m.id != assistantId).toList()
          : state.messages;
      state = state.copyWith(
        messages: messages,
        isAssistantTyping: false,
        clearStreamingMessageId: true,
      );
      onFailure?.call();
    }
  }

  void _markSendFailed(String userMessageId) {
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.id == userMessageId) m.copyWith(sendFailed: true) else m,
      ],
    );
  }

  void setMessageFeedback(String messageId, {bool? helpful, String? reason}) {
    final messages = [
      for (final message in state.messages)
        if (message.id == messageId)
          message.copyWith(
            helpful: helpful,
            notHelpfulReason: reason,
            clearNotHelpfulReason: helpful != false,
          )
        else
          message,
    ];
    state = state.copyWith(messages: messages);
    final conversationId = state.currentConversationId;
    if (conversationId != null) _persist(conversationId, messages);
  }

  Future<void> pickAndUploadStatement() async {
    final picked = await _filePicker.pickStatementFile();
    if (picked == null) return; // user cancelled — no error, no state change

    final attachment = UploadedFileAttachment(
      fileName: picked.name,
      extension: picked.extension,
      sizeBytes: picked.sizeBytes,
    );
    final fileMessageId = 'file-${DateTime.now().microsecondsSinceEpoch}';

    final fileMessage = ChatMessage(
      id: fileMessageId,
      role: ChatMessageRole.user,
      text: '',
      timestamp: DateTime.now(),
      messageType: ChatMessageType.fileAttachment,
      fileAttachment: attachment,
    );

    state = state.copyWith(
      messages: [...state.messages, fileMessage],
      pendingAttachmentMessageId: fileMessageId,
    );

    await Future.delayed(_attachmentConfirmWindow);
    // The user removed it during the confirm window — nothing to analyze.
    if (state.pendingAttachmentMessageId != fileMessageId) return;

    await _runAnalysis(attachment);
  }

  /// Removes a just-attached file before analysis has started.
  void removeAttachment(String messageId) {
    if (state.pendingAttachmentMessageId != messageId) return;
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
      clearPendingAttachment: true,
    );
  }

  Future<void> retryAnalysis() async {
    final attachment = state.lastFailedAttachment;
    if (attachment == null) return;
    await _runAnalysis(attachment);
  }

  Future<void> _runAnalysis(UploadedFileAttachment attachment) async {
    state = state.copyWith(
      isAssistantTyping: true,
      typingLabel: 'Analyzing your statement',
      clearPendingAttachment: true,
      clearLastFailedAttachment: true,
    );

    final String conversationId;
    try {
      conversationId = await _ensureConversation(
        seedTitleFrom: 'Statement analysis',
      );
    } catch (_) {
      state = state.copyWith(isAssistantTyping: false, clearTypingLabel: true);
      return;
    }

    try {
      final result = await _repository.analyzeStatement(attachment);
      final messages = [...state.messages, result.message];
      state = state.copyWith(
        conversations: _touchConversation(conversationId),
        messages: messages,
        isAssistantTyping: false,
        clearTypingLabel: true,
        hasFinancialData: true,
        statementFileName: attachment.fileName,
        statementPeriodStart: result.periodStart,
        statementPeriodEnd: result.periodEnd,
      );
      _persist(conversationId, messages);
    } catch (_) {
      final errorMessage = ChatMessage(
        id: 'error-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.assistant,
        text: "Couldn't analyze this statement. Please try again.",
        timestamp: DateTime.now(),
        messageType: ChatMessageType.analysisError,
        fileAttachment: attachment,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isAssistantTyping: false,
        clearTypingLabel: true,
        lastFailedAttachment: attachment,
      );
    }
  }

  List<Conversation> _touchConversation(
    String conversationId, {
    DateTime? updatedAt,
  }) {
    return [
      for (final c in state.conversations)
        if (c.id == conversationId)
          c.copyWith(updatedAt: updatedAt ?? DateTime.now())
        else
          c,
    ];
  }

  List<ChatMessage> _replaceOrAppend(
    List<ChatMessage> messages,
    String id,
    ChatMessage replacement,
  ) {
    if (messages.any((m) => m.id == id)) {
      return [
        for (final m in messages)
          if (m.id == id) replacement else m,
      ];
    }
    return [...messages, replacement];
  }

  void _persist(String conversationId, List<ChatMessage> messages) {
    final conversation = state.conversations.where(
      (c) => c.id == conversationId,
    );
    if (conversation.isEmpty) return;
    // Fire-and-forget: local caching must never block the chat UI.
    unawaited(_store.saveConversation(_userId, conversation.first, messages));
  }
}
