import '../../../../shared/models/uploaded_file_attachment.dart';
import '../models/chat_stream_chunk.dart';
import '../models/conversation.dart';
import '../models/statement_analysis_result.dart';

/// Thrown when a request needs an access token that's missing, or the
/// backend reports the current one has expired — lets callers distinguish
/// "please log in again" from a generic network/server failure.
class ChatUnauthorizedException implements Exception {
  const ChatUnauthorizedException();
}

/// Thrown when a requested conversation no longer exists on the backend
/// (404) — e.g. it was deleted from another device.
class ChatConversationNotFoundException implements Exception {
  const ChatConversationNotFoundException();
}

/// Source of the AI conversation. The chat UI/controller depends only on
/// this interface, so a real backend-backed `ApiChatRepository` can
/// replace `MockChatRepository` without any UI changes.
///
/// Conversations are first-class on the backend (`User -> Conversations ->
/// Messages`), so this repository owns conversation CRUD as well as
/// sending messages. `LocalConversationStore`/`ChatController` layer a
/// local cache and "which one is current" bookkeeping on top, but the
/// backend is the source of truth whenever it's reachable.
abstract class ChatRepository {
  /// The user's conversations, most-recently-updated first (or in
  /// whatever order the backend returns — `ChatController` sorts
  /// defensively).
  Future<List<Conversation>> getConversations();

  /// Creates a new conversation with [title] and returns it with its
  /// real, backend-assigned id.
  Future<Conversation> createConversation(String title);

  /// Fetches a conversation and its full message history.
  Future<ConversationDetail> getConversation(String conversationId);

  /// Deletes a conversation and its messages on the backend.
  Future<void> deleteConversation(String conversationId);

  /// Streams the assistant's reply to [userMessage] within
  /// [conversationId]. See [ChatStreamChunk] for how implementations are
  /// expected to emit chunks.
  ///
  /// [fileUrl] is the R2-accessible URL of a file the user attached to
  /// this turn (from [FileUploadRepository.uploadFile], already uploaded
  /// by the time this is called) — passed straight through to the
  /// backend so the model can read the document alongside the message.
  Stream<ChatStreamChunk> sendMessage(
    String conversationId,
    String userMessage, {
    String? fileUrl,
  });

  /// Analyzes an uploaded statement file and returns the assistant's
  /// summary plus the period it covers. A separate feature from the
  /// conversation/message endpoints above.
  Future<StatementAnalysisResult> analyzeStatement(UploadedFileAttachment file);

  /// A short, client-derived label for a conversation, built from its
  /// first meaningful message (e.g. "Budget planning"). Synchronous —
  /// this is decorative metadata, not a response — and sent to
  /// `createConversation` since the backend doesn't generate titles yet.
  String suggestTitle(String userMessage);
}
