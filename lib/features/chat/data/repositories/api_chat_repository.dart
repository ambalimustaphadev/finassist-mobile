import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../shared/models/uploaded_file_attachment.dart';
import '../conversation_title.dart';
import '../models/chat_message.dart';
import '../models/chat_stream_chunk.dart';
import '../models/conversation.dart';
import 'chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
    Future<String?> Function()? refreshAccessToken,
    Future<void> Function()? onSessionExpired,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _refreshAccessToken = refreshAccessToken,
       _onSessionExpired = onSessionExpired;

  final String baseUrl;

  final http.Client _client;
  final FlutterSecureStorage _storage;

  /// The existing `AuthRepository.refreshAccessToken()` mechanism,
  /// injected rather than reimplemented here — see [chatRepositoryProvider]
  /// for how production wires this to the real `ApiAuthRepository`. `null`
  /// (the default, e.g. in tests that don't need this behavior) means
  /// "no refresh available," so a 401 surfaces exactly as it always has.
  final Future<String?> Function()? _refreshAccessToken;

  /// Notified when a 401 survives a refresh attempt because the refresh
  /// token itself is genuinely invalid/expired — wired in production to
  /// the existing `AuthController.logout()` so the app's session state
  /// actually transitions to unauthenticated instead of silently staying
  /// "authenticated" while every request fails. Never called for a
  /// network/timeout failure while attempting to refresh.
  final Future<void> Function()? _onSessionExpired;

  static const _accessTokenKey = 'access_token';

  /// Network calls must never hang indefinitely — an unreachable server
  /// should surface as a clear "couldn't connect" state, not an endless
  /// spinner. Used for the plain conversation CRUD endpoints, which do no
  /// AI work server-side and should always answer quickly.
  static const _requestTimeout = Duration(seconds: 12);

  /// `POST /api/chat` specifically needs a much longer budget than plain
  /// CRUD: the backend calls the OpenAI Responses API, and when a
  /// `file_id` is attached it first fetches that document from R2 and
  /// hands it to the model as an `input_file` — genuinely slower than a
  /// quick text-only reply, sometimes well past 12 seconds for a
  /// multi-page statement. Matches `ApiFileUploadRepository`'s own
  /// 60-second allowance for the same "this one is bigger than a normal
  /// JSON request" reason. Using the short [_requestTimeout] here was
  /// cutting document-analysis requests off mid-flight — the request was
  /// still being answered correctly by the backend, but the client had
  /// already given up and shown "Failed to send."
  static const _chatRequestTimeout = Duration(seconds: 90);

  Future<Map<String, String>> _authHeaders() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      throw const ChatUnauthorizedException();
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  /// Sends one authorized request and, if it comes back 401, retries it
  /// exactly once with a freshly refreshed access token — using the
  /// existing refresh mechanism, never a second/duplicate one.
  ///
  /// - A network/timeout failure while refreshing propagates as-is (it is
  ///   NOT caught here), so it flows into the same `_guarded` handling
  ///   every other connection failure already gets — never interpreted
  ///   as an invalid session, never clears any token.
  /// - A definitive refresh failure (no refresh token, or the server
  ///   explicitly rejected it — [_refreshAccessToken] returns `null`)
  ///   notifies [_onSessionExpired] and throws [ChatUnauthorizedException],
  ///   the same exception every other unauthorized case here already
  ///   throws.
  /// - The retried request's own result (success or otherwise, including
  ///   a second 401) is returned as-is, exactly once — this method never
  ///   retries more than that single time, so a second 401 cannot loop.
  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    final response = await send(await _authHeaders());
    if (response.statusCode != 401) return response;

    final refresh = _refreshAccessToken;
    if (refresh == null) throw const ChatUnauthorizedException();

    final newAccessToken = await refresh();
    if (newAccessToken == null) {
      final onExpired = _onSessionExpired;
      if (onExpired != null) unawaited(onExpired());
      throw const ChatUnauthorizedException();
    }

    return send(await _authHeaders());
  }

  /// Runs [action], normalizing every failure mode into the shared chat
  /// exception vocabulary: [ChatUnauthorizedException] and
  /// [ChatConversationNotFoundException] pass through unchanged so callers
  /// can branch on them; a timeout becomes a plain, friendly connection
  /// error; anything else is wrapped with [context] for a clearer message.
  Future<T> _guarded<T>(String context, Future<T> Function() action) async {
    try {
      return await action();
    } on ChatUnauthorizedException {
      rethrow;
    } on ChatConversationNotFoundException {
      rethrow;
    } on TimeoutException {
      if (kDebugMode) debugPrint('[chat] $context: timed out');
      throw Exception(
        "Couldn't connect. Please check your connection and try again.",
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[chat] $context: $error');
      throw Exception('$context: $error');
    }
  }

  void _throwOnErrorStatus(http.Response response, String context) {
    if (response.statusCode == 401) throw const ChatUnauthorizedException();
    if (response.statusCode == 404) {
      throw const ChatConversationNotFoundException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$context: ${response.statusCode}');
    }
  }

  @override
  Future<List<Conversation>> getConversations() {
    return _guarded('Unable to load conversations', () async {
      final response = await _authorizedRequest(
        (headers) => _client
            .get(Uri.parse('$baseUrl/api/conversations'), headers: headers)
            .timeout(_requestTimeout),
      );
      _throwOnErrorStatus(response, 'Failed to load conversations');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['conversations'];
      final list = raw is List ? raw : const [];
      return list
          .map((e) => Conversation.fromApiJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Conversation> createConversation(String title) {
    return _guarded('Unable to create conversation', () async {
      final response = await _authorizedRequest(
        (headers) => _client
            .post(
              Uri.parse('$baseUrl/api/conversations'),
              headers: headers,
              body: jsonEncode({'title': title}),
            )
            .timeout(_requestTimeout),
      );
      _throwOnErrorStatus(response, 'Failed to create conversation');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Conversation.fromApiJson(
        data['conversation'] as Map<String, dynamic>,
      );
    });
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) {
    return _guarded('Unable to load conversation', () async {
      final response = await _authorizedRequest(
        (headers) => _client
            .get(
              Uri.parse('$baseUrl/api/conversations/$conversationId'),
              headers: headers,
            )
            .timeout(_requestTimeout),
      );
      _throwOnErrorStatus(response, 'Failed to load conversation');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final conversation = Conversation.fromApiJson(
        data['conversation'] as Map<String, dynamic>,
      );
      final rawMessages = data['messages'];
      final messages = (rawMessages is List ? rawMessages : const [])
          .map(
            (e) =>
                _messageFromApiJson(e as Map<String, dynamic>, conversation.id),
          )
          .toList();
      return ConversationDetail(conversation: conversation, messages: messages);
    });
  }

  @override
  Future<void> deleteConversation(String conversationId) {
    return _guarded('Unable to delete conversation', () async {
      final response = await _authorizedRequest(
        (headers) => _client
            .delete(
              Uri.parse('$baseUrl/api/conversations/$conversationId'),
              headers: headers,
            )
            .timeout(_requestTimeout),
      );
      _throwOnErrorStatus(response, 'Failed to delete conversation');
    });
  }

  @override
  Stream<ChatStreamChunk> sendMessage(
    String conversationId,
    String userMessage, {
    int? fileId,
  }) async* {
    // A file-only turn (the user attached a document and sent it with no
    // typed text — e.g. right after the assistant asks for a statement)
    // omits `message` entirely rather than sending an empty string: the
    // backend expects either a real message or the key absent, and a
    // literal `""` was being rejected outright.
    final hasMessage = userMessage.isNotEmpty;

    if (kDebugMode) {
      debugPrint(
        '[chat] sending -> conversation_id=$conversationId '
        'message=${hasMessage ? "present(length=${userMessage.length})" : "absent"} '
        'file_id=${fileId ?? "absent"}',
      );
    }

    final result = await _guarded(
      'Unable to get a response from FinAssist',
      () async {
        // Exactly one 401-triggered retry, reusing the same request body
        // each time — see [_authorizedRequest]'s doc comment. The retry
        // happens entirely inside this awaited call, before anything is
        // ever yielded below, so a retry can never produce a duplicate
        // delta/done pair.
        final response = await _authorizedRequest(
          (headers) => _client
              .post(
                Uri.parse('$baseUrl/api/chat'),
                headers: headers,
                body: jsonEncode({
                  'conversation_id':
                      int.tryParse(conversationId) ?? conversationId,
                  'message': ?(hasMessage ? userMessage : null),
                  'file_id': ?fileId,
                }),
              )
              // A file attachment means the backend fetches it from R2
              // and hands it to OpenAI's Responses API before replying —
              // meaningfully slower than a plain text round trip, so this
              // gets the longer chat-specific budget rather than the
              // short one used for plain CRUD calls.
              .timeout(_chatRequestTimeout),
        );

        if (kDebugMode) {
          debugPrint('[chat] response <- status=${response.statusCode}');
          if (response.statusCode < 200 || response.statusCode >= 300) {
            debugPrint('[chat] error body <- ${response.body}');
          }
        }

        _throwOnErrorStatus(response, 'Chat request failed');

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final aiResponse = data['response'];
        if (aiResponse == null || aiResponse.toString().trim().isEmpty) {
          throw Exception('The server returned an empty response.');
        }

        return (
          text: aiResponse.toString(),
          // Optional, forward-compatible field: absent from today's
          // contract, read only if a future backend adds it. Never
          // fabricated here — see ChatMessage.usedFinancialData.
          usedFinancialData: data['used_financial_data'] as bool?,
        );
      },
    );

    final message = ChatMessage(
      id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatMessageRole.assistant,
      text: result.text,
      timestamp: DateTime.now(),
      conversationId: conversationId,
      usedFinancialData: result.usedFinancialData,
    );

    // Today's backend answers atomically, so this is a single delta
    // followed immediately by "done" — see ChatStreamChunk's doc comment
    // for how this generalizes to real streaming later.
    yield ChatStreamChunk.delta(result.text);
    yield ChatStreamChunk.done(message);
  }

  ChatMessage _messageFromApiJson(
    Map<String, dynamic> json,
    String conversationId,
  ) {
    final parsed = _parseContent(json['content']);
    return ChatMessage(
      id: 'msg-${json['id']}',
      role: json['role'] == 'user'
          ? ChatMessageRole.user
          : ChatMessageRole.assistant,
      text: parsed.text,
      timestamp:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      conversationId: conversationId,
      fileAttachment: parsed.fileAttachment,
    );
  }

  /// A message's `content` arrives in one of three shapes: a plain
  /// string; a JSON array of OpenAI-style content parts
  /// (`[{"type": "input_text", "text": ...}, {"type": "input_file",
  /// "file_id": ...}]`, see `chat_routes.py`'s `_serialize_content`); or —
  /// for older attachment messages stored before that array format —
  /// a flat `{"text": ..., "file_id": ...}` object. Reconstructs both the
  /// display text and a tappable [UploadedFileAttachment] from any of the
  /// three, so reopening an old conversation never loses a past file
  /// reference or, worse, renders the raw JSON/Map to the user. A bare
  /// `file_id` carries no filename, so a restored historical attachment
  /// always shows a generic label — the real filename is only known at
  /// the moment of upload (see [ChatController.sendMessage]).
  ({String text, UploadedFileAttachment? fileAttachment}) _parseContent(
    Object? content,
  ) {
    if (content is Map) {
      final text = (content['text'] ?? '').toString();
      final rawFileId = content['file_id'];
      final fileId = rawFileId is int
          ? rawFileId
          : int.tryParse(rawFileId?.toString() ?? '');
      return (
        text: text,
        fileAttachment: fileId == null
            ? null
            : UploadedFileAttachment(
                fileName: 'Attached document',
                fileId: fileId,
              ),
      );
    }

    if (content is! List) {
      return (text: (content ?? '').toString(), fileAttachment: null);
    }

    String text = '';
    int? fileId;
    for (final part in content) {
      if (part is! Map) continue;
      switch (part['type']) {
        case 'input_text':
          text = (part['text'] ?? '').toString();
        case 'input_file':
          final id = part['file_id'];
          if (id is int) {
            fileId = id;
          } else if (id != null) {
            fileId = int.tryParse(id.toString());
          }
      }
    }

    if (fileId == null) return (text: text, fileAttachment: null);
    return (
      text: text,
      fileAttachment: UploadedFileAttachment(
        fileName: 'Attached document',
        fileId: fileId,
      ),
    );
  }

  @override
  String suggestTitle(String userMessage) =>
      suggestConversationTitle(userMessage);
}
