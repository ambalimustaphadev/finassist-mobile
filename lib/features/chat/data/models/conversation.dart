import 'chat_message.dart';

/// A single conversation thread, independent of its messages.
///
/// Mirrors `User -> Conversations -> Messages` on the backend
/// (`/api/conversations`). No `userId` field: the JWT already scopes every
/// request to the authenticated user, so the backend never returns one and
/// Flutter never needs to send one.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The backend's numeric conversation id, kept as a string on this side
  /// since every other id in the chat feature (messages, attachments) is
  /// already a string — call sites that build a request body convert back
  /// with `int.tryParse` where the wire format needs a number.
  final String id;

  /// Short, meaningful label — derived from the first user message today
  /// (see `ChatRepository.suggestTitle`) and sent to the backend when the
  /// conversation is created, or provided by the backend directly once it
  /// generates titles itself.
  final String title;

  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation copyWith({String? title, DateTime? updatedAt}) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parses a conversation as returned by the Flask backend
  /// (`/api/conversations`), e.g. `{"id": 1, "title": "...",
  /// "created_at": "...", "updated_at": "..."}`.
  factory Conversation.fromApiJson(Map<String, dynamic> json) {
    final title = json['title']?.toString().trim();
    return Conversation(
      id: json['id'].toString(),
      title: (title == null || title.isEmpty) ? 'Conversation' : title,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Local cache format used by `LocalConversationStore` — deliberately
  /// separate from [fromApiJson]/the backend's snake_case wire format, so
  /// the two can evolve independently.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// A conversation plus its full message history, as returned by
/// `GET /api/conversations/<id>`.
class ConversationDetail {
  const ConversationDetail({
    required this.conversation,
    required this.messages,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;
}
