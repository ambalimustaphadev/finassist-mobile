import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finassist/features/chat/data/models/chat_message.dart';
import 'package:finassist/features/chat/data/repositories/api_chat_repository.dart';
import 'package:finassist/features/chat/data/repositories/chat_repository.dart';

/// `FlutterSecureStorage` talks to native code over a MethodChannel, which
/// doesn't exist in a widget-test environment — mock it with a simple
/// in-memory map so `ApiChatRepository` can use the real class exactly as
/// production does, rather than needing a storage abstraction it doesn't
/// otherwise have.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(
  TestWidgetsFlutterBinding binding,
  Map<String, String> values,
) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return values[call.arguments['key']];
        case 'write':
          values[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        default:
          return null;
      }
    },
  );
}

ApiChatRepository _repo(http.Client client) {
  return ApiChatRepository(
    baseUrl: 'http://test',
    client: client,
    storage: const FlutterSecureStorage(),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _secureStorageChannel,
      null,
    );
  });

  group('getConversations', () {
    test('parses the conversation list and sends the bearer token', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/conversations');
        expect(request.headers['Authorization'], 'Bearer token-123');
        return http.Response(
          jsonEncode({
            'conversations': [
              {
                'id': 1,
                'title': 'Food spending',
                'created_at': '2026-01-01T10:00:00Z',
                'updated_at': '2026-01-02T10:00:00Z',
              },
            ],
          }),
          200,
        );
      });

      final conversations = await _repo(client).getConversations();

      expect(conversations, hasLength(1));
      expect(conversations.single.id, '1');
      expect(conversations.single.title, 'Food spending');
    });

    test('401 throws ChatUnauthorizedException', () async {
      _mockSecureStorage(binding, {'access_token': 'expired'});
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
      });

      expect(
        _repo(client).getConversations(),
        throwsA(isA<ChatUnauthorizedException>()),
      );
    });

    test(
      'no stored token throws ChatUnauthorizedException without a network call',
      () async {
        _mockSecureStorage(binding, {});
        var requested = false;
        final client = MockClient((request) async {
          requested = true;
          return http.Response('{}', 200);
        });

        await expectLater(
          _repo(client).getConversations(),
          throwsA(isA<ChatUnauthorizedException>()),
        );
        expect(requested, isFalse);
      },
    );

    test('network failure throws a clear connection error', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        throw Exception('socket closed');
      });

      expect(_repo(client).getConversations(), throwsException);
    });
  });

  group('createConversation', () {
    test('posts the title and returns the created conversation', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/conversations');
        expect(jsonDecode(request.body), {'title': 'Budget planning'});
        return http.Response(
          jsonEncode({
            'conversation': {
              'id': 42,
              'title': 'Budget planning',
              'created_at': '2026-01-01T10:00:00Z',
              'updated_at': '2026-01-01T10:00:00Z',
            },
          }),
          200,
        );
      });

      final conversation = await _repo(
        client,
      ).createConversation('Budget planning');

      expect(conversation.id, '42');
      expect(conversation.title, 'Budget planning');
    });
  });

  group('getConversation', () {
    test('parses the conversation and its messages', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        expect(request.url.path, '/api/conversations/1');
        return http.Response(
          jsonEncode({
            'conversation': {
              'id': 1,
              'title': 'Food spending',
              'created_at': '2026-01-01T10:00:00Z',
              'updated_at': '2026-01-01T10:00:00Z',
            },
            'messages': [
              {
                'id': 1,
                'conversation_id': 1,
                'role': 'user',
                'content': 'How much did I spend?',
                'created_at': '2026-01-01T10:00:00Z',
              },
              {
                'id': 2,
                'conversation_id': 1,
                'role': 'assistant',
                'content': 'You spent ₦50,000...',
                'created_at': '2026-01-01T10:00:05Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      expect(detail.conversation.id, '1');
      expect(detail.messages, hasLength(2));
      expect(detail.messages[0].role, ChatMessageRole.user);
      expect(detail.messages[0].text, 'How much did I spend?');
      expect(detail.messages[0].conversationId, '1');
      expect(detail.messages[1].role, ChatMessageRole.assistant);
      expect(detail.messages[1].text, 'You spent ₦50,000...');
    });

    test('404 throws ChatConversationNotFoundException', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      expect(
        _repo(client).getConversation('999'),
        throwsA(isA<ChatConversationNotFoundException>()),
      );
    });

    test('a message whose content is a file-attachment content-parts list '
        'restores its text and a tappable fileAttachment, not a mangled '
        'string', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'conversation': {
              'id': 1,
              'title': 'Statement review',
              'created_at': '2026-01-01T10:00:00Z',
              'updated_at': '2026-01-01T10:00:00Z',
            },
            'messages': [
              {
                'id': 1,
                'conversation_id': 1,
                'role': 'user',
                'content': [
                  {'type': 'input_text', 'text': 'Summarize this statement.'},
                  {
                    'type': 'input_file',
                    'file_url': 'https://pub-test.r2.dev/statement/4/uuid.pdf',
                  },
                ],
                'created_at': '2026-01-01T10:00:00Z',
              },
              {
                'id': 2,
                'conversation_id': 1,
                'role': 'assistant',
                'content': 'Here is a summary...',
                'created_at': '2026-01-01T10:00:05Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      final userMessage = detail.messages[0];
      expect(userMessage.text, 'Summarize this statement.');
      expect(userMessage.fileAttachment, isNotNull);
      expect(
        userMessage.fileAttachment!.fileUrl,
        'https://pub-test.r2.dev/statement/4/uuid.pdf',
      );
      // The extension is preserved even though the original filename
      // wasn't stored — enough for the document viewer to work and to
      // show something more honest than a raw UUID.
      expect(userMessage.fileAttachment!.fileName, endsWith('.pdf'));

      // The plain-text assistant reply right after it is unaffected.
      expect(detail.messages[1].text, 'Here is a summary...');
      expect(detail.messages[1].fileAttachment, isNull);
    });
  });

  group('deleteConversation', () {
    test('sends a DELETE to the conversation endpoint', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/conversations/1');
        return http.Response('', 204);
      });

      await _repo(client).deleteConversation('1');
    });

    test('404 throws ChatConversationNotFoundException', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      expect(
        _repo(client).deleteConversation('999'),
        throwsA(isA<ChatConversationNotFoundException>()),
      );
    });
  });

  group('sendMessage', () {
    test(
      'posts conversation_id and message, emits a delta then a done chunk',
      () async {
        _mockSecureStorage(binding, {'access_token': 'token-123'});
        final client = MockClient((request) async {
          expect(request.url.path, '/api/chat');
          expect(jsonDecode(request.body), {
            'conversation_id': 1,
            'message': 'How much did I spend?',
          });
          return http.Response(
            jsonEncode({'response': 'You spent ₦12,000 on food.'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final chunks = await _repo(
          client,
        ).sendMessage('1', 'How much did I spend?').toList();

        expect(chunks, hasLength(2));
        expect(chunks.first.isDone, isFalse);
        expect(chunks.first.textDelta, 'You spent ₦12,000 on food.');
        expect(chunks.last.isDone, isTrue);
        expect(chunks.last.message!.text, 'You spent ₦12,000 on food.');
        expect(chunks.last.message!.conversationId, '1');
      },
    );

    test('surfaces used_financial_data when the backend includes it', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'response': 'Based on your data...',
            'used_financial_data': true,
          }),
          200,
        );
      });

      final chunks = await _repo(client).sendMessage('1', 'hi').toList();

      expect(chunks.last.message!.usedFinancialData, isTrue);
    });

    test('401 throws ChatUnauthorizedException', () async {
      _mockSecureStorage(binding, {'access_token': 'expired'});
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
      });

      expect(
        _repo(client).sendMessage('1', 'hi').toList(),
        throwsA(isA<ChatUnauthorizedException>()),
      );
    });

    test('404 throws ChatConversationNotFoundException', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      expect(
        _repo(client).sendMessage('999', 'hi').toList(),
        throwsA(isA<ChatConversationNotFoundException>()),
      );
    });
  });
}
