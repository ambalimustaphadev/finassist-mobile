import '../../data/models/chat_message.dart';
import '../../data/models/conversation.dart';

/// Status of loading the conversation list / the active conversation's
/// messages — drives which of the intentional loading/error/empty states
/// the chat screen shows instead of a blank screen or an endless spinner.
enum ConversationLoadStatus { loading, loaded, error }

/// Immutable state for the chat screen: the recent-conversations list, the
/// active conversation's messages, and whether the assistant is currently
/// replying.
class ChatState {
  const ChatState({
    this.conversations = const [],
    this.currentConversationId,
    this.conversationStatus = ConversationLoadStatus.loading,
    this.conversationError,
    this.messages = const [],
    this.isAssistantTyping = false,
    this.typingLabel,
    this.streamingMessageId,
    this.attachmentUploadError,
  });

  /// Recent conversations, most-recently-updated first. Backed by the
  /// backend's `/api/conversations` when reachable, with
  /// `LocalConversationStore` as an offline fallback/cache.
  final List<Conversation> conversations;

  /// Null when the active thread hasn't had its first message sent yet —
  /// it isn't materialized/persisted until then, so it never shows up as a
  /// stray "New conversation" entry in the drawer.
  final String? currentConversationId;

  final ConversationLoadStatus conversationStatus;

  /// User-facing message for [ConversationLoadStatus.error], e.g. "session
  /// expired" vs. a generic connection failure.
  final String? conversationError;

  final List<ChatMessage> messages;
  final bool isAssistantTyping;

  /// Optional small caption shown above the typing dots, e.g. "Uploading
  /// statement.pdf...". This is also the seam for future AI agent/tool
  /// status messages once the backend can report which tool it's
  /// currently calling — nothing fabricates those today.
  final String? typingLabel;

  /// The id of the assistant message currently receiving streamed text, if
  /// any — lets the bubble show a subtle in-progress affordance without
  /// the whole screen re-rendering.
  final String? streamingMessageId;

  /// A one-shot, user-facing message set when uploading a composer
  /// attachment fails (so the chat request is never sent) — the chat
  /// screen shows it as a snackbar and immediately dismisses it, the same
  /// transient-feedback pattern [conversationError] uses for a different
  /// case.
  final String? attachmentUploadError;

  bool get isNewConversation => currentConversationId == null;

  ChatState copyWith({
    List<Conversation>? conversations,
    String? currentConversationId,
    bool clearCurrentConversationId = false,
    ConversationLoadStatus? conversationStatus,
    String? conversationError,
    bool clearConversationError = false,
    List<ChatMessage>? messages,
    bool? isAssistantTyping,
    String? typingLabel,
    bool clearTypingLabel = false,
    String? streamingMessageId,
    bool clearStreamingMessageId = false,
    String? attachmentUploadError,
    bool clearAttachmentUploadError = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentConversationId: clearCurrentConversationId
          ? null
          : (currentConversationId ?? this.currentConversationId),
      conversationStatus: conversationStatus ?? this.conversationStatus,
      conversationError: clearConversationError
          ? null
          : (conversationError ?? this.conversationError),
      messages: messages ?? this.messages,
      isAssistantTyping: isAssistantTyping ?? this.isAssistantTyping,
      typingLabel: clearTypingLabel ? null : (typingLabel ?? this.typingLabel),
      streamingMessageId: clearStreamingMessageId
          ? null
          : (streamingMessageId ?? this.streamingMessageId),
      attachmentUploadError: clearAttachmentUploadError
          ? null
          : (attachmentUploadError ?? this.attachmentUploadError),
    );
  }
}
