import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../shared/models/uploaded_file_attachment.dart';
import '../conversation_title.dart';
import '../models/chat_message.dart';
import '../models/chat_stream_chunk.dart';
import '../models/conversation.dart';
import '../models/statement_analysis_result.dart';
import 'chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;

  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';

  /// Network calls must never hang indefinitely — an unreachable server
  /// should surface as a clear "couldn't connect" state, not an endless
  /// spinner.
  static const _requestTimeout = Duration(seconds: 12);

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
      throw Exception(
        "Couldn't connect. Please check your connection and try again.",
      );
    } catch (error) {
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
      final headers = await _authHeaders();
      final response = await _client
          .get(Uri.parse('$baseUrl/api/conversations'), headers: headers)
          .timeout(_requestTimeout);
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
      final headers = await _authHeaders();
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/conversations'),
            headers: headers,
            body: jsonEncode({'title': title}),
          )
          .timeout(_requestTimeout);
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
      final headers = await _authHeaders();
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/conversations/$conversationId'),
            headers: headers,
          )
          .timeout(_requestTimeout);
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
      final headers = await _authHeaders();
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/api/conversations/$conversationId'),
            headers: headers,
          )
          .timeout(_requestTimeout);
      _throwOnErrorStatus(response, 'Failed to delete conversation');
    });
  }

  @override
  Stream<ChatStreamChunk> sendMessage(
    String conversationId,
    String userMessage, {
    String? fileUrl,
  }) async* {
    final result = await _guarded(
      'Unable to get a response from FinAssist',
      () async {
        final headers = await _authHeaders();
        final response = await _client
            .post(
              Uri.parse('$baseUrl/api/chat'),
              headers: headers,
              body: jsonEncode({
                'conversation_id':
                    int.tryParse(conversationId) ?? conversationId,
                'message': userMessage,
                'file_url': ?fileUrl,
              }),
            )
            .timeout(_requestTimeout);
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
    return ChatMessage(
      id: 'msg-${json['id']}',
      role: json['role'] == 'user'
          ? ChatMessageRole.user
          : ChatMessageRole.assistant,
      text: (json['content'] ?? '').toString(),
      timestamp:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      conversationId: conversationId,
    );
  }

  @override
  Future<StatementAnalysisResult> analyzeStatement(
    UploadedFileAttachment file,
  ) async {
    throw UnimplementedError('Real statement analysis will be connected next.');
  }

  @override
  String suggestTitle(String userMessage) =>
      suggestConversationTitle(userMessage);
}
