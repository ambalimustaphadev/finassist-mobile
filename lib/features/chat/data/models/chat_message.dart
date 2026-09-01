import '../../../../shared/models/category_breakdown.dart';
import '../../../../shared/models/uploaded_file_attachment.dart';
import 'recurring_payment.dart';

enum ChatMessageRole { user, assistant }

/// Determines which widget renders the message body inside a [ChatBubble].
enum ChatMessageType {
  text,
  categoryBreakdown,
  recurringPayments,

  /// A file the user attached to the conversation (e.g. a bank statement).
  fileAttachment,

  /// An assistant message that ends with an "Upload Statement" affordance
  /// because it needs transaction data it doesn't have yet.
  uploadPrompt,

  /// Statement analysis failed — offers "Try again" / "Choose another file".
  analysisError,
}

/// A single message in the AI conversation. The chat UI renders purely
/// from this model, so it never needs to know whether the data came from
/// mock responses or a real backend.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.conversationId,
    this.messageType = ChatMessageType.text,
    this.highlights = const [],
    this.categoryBreakdown,
    this.recurringPayments,
    this.fileAttachment,
    this.followUpSuggestions = const [],
    this.helpful,
    this.notHelpfulReason,
    this.usedFinancialData,
    this.sendFailed = false,
    this.pendingFileUrl,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime timestamp;

  /// The conversation this message belongs to. Nullable for now since
  /// today's backend has no conversation concept — populated once the
  /// backend's `Conversations -> Messages` endpoints exist.
  final String? conversationId;

  final ChatMessageType messageType;

  /// Substrings of [text] rendered in the accent color.
  final List<String> highlights;

  /// Populated when [messageType] is [ChatMessageType.categoryBreakdown].
  final CategoryBreakdown? categoryBreakdown;

  /// Populated when [messageType] is [ChatMessageType.recurringPayments].
  final List<RecurringPayment>? recurringPayments;

  /// Populated when [messageType] is [ChatMessageType.fileAttachment] or
  /// [ChatMessageType.analysisError] (the file that failed to analyze).
  final UploadedFileAttachment? fileAttachment;

  /// The R2 file_url already uploaded for this (user) message, if any —
  /// carried only so [ChatController.retrySend] can resend the same chat
  /// request without re-uploading a file that already succeeded. Purely
  /// in-memory bookkeeping, never persisted (see [toJson]) and never
  /// rendered — [fileAttachment] is what the UI shows.
  final String? pendingFileUrl;

  /// Contextual prompts shown as chips beneath a substantive assistant
  /// answer, e.g. "Show transactions", "Compare with last month".
  final List<String> followUpSuggestions;

  /// User's "was this helpful?" response for this assistant message. Null
  /// until rated.
  final bool? helpful;

  /// Reason picked after marking a message not helpful, if any.
  final String? notHelpfulReason;

  /// Whether the assistant used the user's real financial data to answer —
  /// null until the backend tells Flutter so (there is no client-side
  /// guessing). When true, the bubble shows a subtle "Based on your
  /// financial data" caption.
  final bool? usedFinancialData;

  /// True when this (user) message failed to send — shows a small inline
  /// retry affordance instead of pretending the message went through.
  final bool sendFailed;

  ChatMessage copyWith({
    String? text,
    bool? helpful,
    bool clearHelpful = false,
    String? notHelpfulReason,
    bool clearNotHelpfulReason = false,
    bool? sendFailed,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp,
      conversationId: conversationId,
      messageType: messageType,
      highlights: highlights,
      categoryBreakdown: categoryBreakdown,
      recurringPayments: recurringPayments,
      fileAttachment: fileAttachment,
      followUpSuggestions: followUpSuggestions,
      helpful: clearHelpful ? null : (helpful ?? this.helpful),
      notHelpfulReason: clearNotHelpfulReason
          ? null
          : (notHelpfulReason ?? this.notHelpfulReason),
      usedFinancialData: usedFinancialData,
      sendFailed: sendFailed ?? this.sendFailed,
      pendingFileUrl: pendingFileUrl,
    );
  }

  /// Local persistence only (`LocalConversationStore`) — deliberately drops
  /// [categoryBreakdown]/[recurringPayments]/[fileAttachment], which are
  /// mock-data-only rich cards today. Restored history falls back to the
  /// plain [text], which still carries the meaningful content.
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'conversationId': conversationId,
    'highlights': highlights,
    'followUpSuggestions': followUpSuggestions,
    'helpful': helpful,
    'notHelpfulReason': notHelpfulReason,
    'usedFinancialData': usedFinancialData,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] == 'user'
          ? ChatMessageRole.user
          : ChatMessageRole.assistant,
      text: (json['text'] as String?) ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      conversationId: json['conversationId'] as String?,
      highlights:
          (json['highlights'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      followUpSuggestions:
          (json['followUpSuggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      helpful: json['helpful'] as bool?,
      notHelpfulReason: json['notHelpfulReason'] as String?,
      usedFinancialData: json['usedFinancialData'] as bool?,
    );
  }
}
