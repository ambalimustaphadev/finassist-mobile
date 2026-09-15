import '../../../../shared/models/uploaded_file_attachment.dart';

enum ChatMessageRole { user, assistant }

/// A single message in the AI conversation. The chat UI renders purely
/// from this model, so it never needs to know whether the data came from
/// mock responses or a real backend. Every AI response is plain chat text
/// (optionally with a document attachment) — never a fabricated financial
/// dashboard card.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.conversationId,
    this.fileAttachment,
    this.followUpSuggestions = const [],
    this.helpful,
    this.notHelpfulReason,
    this.usedFinancialData,
    this.sendFailed = false,
    this.pendingFileId,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final DateTime timestamp;

  /// The conversation this message belongs to. Nullable for now since
  /// today's backend has no conversation concept — populated once the
  /// backend's `Conversations -> Messages` endpoints exist.
  final String? conversationId;

  /// A file the user attached to this turn (e.g. a bank statement), if
  /// any.
  final UploadedFileAttachment? fileAttachment;

  /// The `file_id` already uploaded for this (user) message, if any —
  /// carried only so [ChatController.retrySend] can resend the same chat
  /// request without re-uploading a file that already succeeded. Purely
  /// in-memory bookkeeping, never persisted (see [toJson]) and never
  /// rendered — [fileAttachment] is what the UI shows.
  final int? pendingFileId;

  /// Contextual prompts shown as chips beneath a substantive assistant
  /// answer, e.g. "Explain this differently", "Tell me more".
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
      fileAttachment: fileAttachment,
      followUpSuggestions: followUpSuggestions,
      helpful: clearHelpful ? null : (helpful ?? this.helpful),
      notHelpfulReason: clearNotHelpfulReason
          ? null
          : (notHelpfulReason ?? this.notHelpfulReason),
      usedFinancialData: usedFinancialData,
      sendFailed: sendFailed ?? this.sendFailed,
      pendingFileId: pendingFileId,
    );
  }

  /// Local persistence only (`LocalConversationStore`). [fileAttachment]
  /// is kept (just its [UploadedFileAttachment] `fileName`/`fileId`/
  /// `contentType`, not the derived size/extension labels) so a
  /// conversation restored from the offline cache still shows a tappable
  /// document reference, not just its plain [text]. Never caches a URL —
  /// [fileId] is the only identity persisted; viewing the document later
  /// always asks the backend for a fresh signed URL.
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'conversationId': conversationId,
    'followUpSuggestions': followUpSuggestions,
    'helpful': helpful,
    'notHelpfulReason': notHelpfulReason,
    'usedFinancialData': usedFinancialData,
    'fileAttachment': fileAttachment == null
        ? null
        : {
            'fileName': fileAttachment!.fileName,
            'fileId': fileAttachment!.fileId,
            'contentType': fileAttachment!.contentType,
          },
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAttachment = json['fileAttachment'];
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
      followUpSuggestions:
          (json['followUpSuggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      helpful: json['helpful'] as bool?,
      notHelpfulReason: json['notHelpfulReason'] as String?,
      usedFinancialData: json['usedFinancialData'] as bool?,
      fileAttachment: rawAttachment is Map
          ? UploadedFileAttachment(
              fileName:
                  (rawAttachment['fileName'] as String?) ?? 'Attached document',
              fileId: rawAttachment['fileId'] is int
                  ? rawAttachment['fileId'] as int
                  : int.tryParse(rawAttachment['fileId']?.toString() ?? ''),
              contentType: rawAttachment['contentType'] as String?,
            )
          : null,
    );
  }
}
