import 'chat_message.dart';

/// One event from `ChatRepository.sendMessage`'s response stream.
///
/// Today's Flask backend answers `POST /api/chat` with the full reply in a
/// single JSON body, so implementations emit exactly one [textDelta] chunk
/// (the whole reply) followed by one "done" chunk. The controller consumes
/// this the same way it would consume a real token-by-token stream, so
/// when the backend later supports chunked/SSE streaming, only the
/// repository implementation changes — the controller and UI already
/// append deltas as they arrive.
class ChatStreamChunk {
  const ChatStreamChunk.delta(this.textDelta) : message = null;

  const ChatStreamChunk.done(ChatMessage this.message) : textDelta = '';

  /// Text to append to the growing assistant message. Empty on the final
  /// ("done") chunk.
  final String textDelta;

  /// Set only on the final chunk — the complete message with all metadata
  /// (highlights, follow-ups, structured cards, etc.) built from the full
  /// accumulated response.
  final ChatMessage? message;

  bool get isDone => message != null;
}
