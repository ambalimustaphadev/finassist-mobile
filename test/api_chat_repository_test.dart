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

ApiChatRepository _repo(
  http.Client client, {
  Future<String?> Function()? refreshAccessToken,
  Future<void> Function()? onSessionExpired,
}) {
  return ApiChatRepository(
    baseUrl: 'http://test',
    client: client,
    storage: const FlutterSecureStorage(),
    refreshAccessToken: refreshAccessToken,
    onSessionExpired: onSessionExpired,
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
                  {'type': 'input_file', 'file_id': 4},
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
      expect(userMessage.fileAttachment!.fileId, 4);

      // The plain-text assistant reply right after it is unaffected.
      expect(detail.messages[1].text, 'Here is a summary...');
      expect(detail.messages[1].fileAttachment, isNull);
    });

    test('a historical attachment message whose content is a flat '
        '{text, file_id} Map (an older storage shape than the input-parts '
        'list) restores its text and a tappable fileAttachment, never the '
        'raw Map', () async {
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
                'content': {
                  'text': 'Please analyze this statement',
                  'file_id': 123,
                },
                'created_at': '2026-01-01T10:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      final message = detail.messages.single;
      expect(message.text, 'Please analyze this statement');
      expect(message.fileAttachment, isNotNull);
      expect(message.fileAttachment!.fileId, 123);
      // Never the raw Dart Map rendered as text.
      expect(message.text, isNot(contains('{')));
    });

    test('a {text} Map with no file_id restores just the text, with no '
        'attachment', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'conversation': {
              'id': 1,
              'title': 'Chat',
              'created_at': '2026-01-01T10:00:00Z',
              'updated_at': '2026-01-01T10:00:00Z',
            },
            'messages': [
              {
                'id': 1,
                'conversation_id': 1,
                'role': 'user',
                'content': {'text': 'Just a question, no attachment'},
                'created_at': '2026-01-01T10:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      final message = detail.messages.single;
      expect(message.text, 'Just a question, no attachment');
      expect(message.fileAttachment, isNull);
    });

    test('a {file_id} Map with no text restores just the attachment, with '
        'empty (not fabricated) text', () async {
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
                'content': {'file_id': 7},
                'created_at': '2026-01-01T10:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      final message = detail.messages.single;
      expect(message.text, isEmpty);
      expect(message.fileAttachment, isNotNull);
      expect(message.fileAttachment!.fileId, 7);
    });

    test('a malformed content Map (unexpected keys, no text or file_id) '
        'degrades to empty text with no attachment rather than crashing or '
        'rendering the raw Map', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'conversation': {
              'id': 1,
              'title': 'Chat',
              'created_at': '2026-01-01T10:00:00Z',
              'updated_at': '2026-01-01T10:00:00Z',
            },
            'messages': [
              {
                'id': 1,
                'conversation_id': 1,
                'role': 'user',
                'content': {'unexpected_key': 'garbage', 'file_id': 'oops'},
                'created_at': '2026-01-01T10:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      final message = detail.messages.single;
      expect(message.text, isEmpty);
      // 'oops' doesn't parse as an int — no fabricated attachment.
      expect(message.fileAttachment, isNull);
    });

    test('a null content value degrades to empty text, not "null"', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'conversation': {
              'id': 1,
              'title': 'Chat',
              'created_at': '2026-01-01T10:00:00Z',
              'updated_at': '2026-01-01T10:00:00Z',
            },
            'messages': [
              {
                'id': 1,
                'conversation_id': 1,
                'role': 'user',
                'content': null,
                'created_at': '2026-01-01T10:00:00Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final detail = await _repo(client).getConversation('1');

      expect(detail.messages.single.text, isEmpty);
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

    test(
      'a document attachment sends file_id (not file_url) alongside message '
      'and conversation_id, matching the new backend contract exactly — '
      "proves the composer's uploaded file_id actually reaches /api/chat",
      () async {
        _mockSecureStorage(binding, {'access_token': 'token-123'});
        final client = MockClient((request) async {
          expect(request.url.path, '/api/chat');
          expect(jsonDecode(request.body), {
            'conversation_id': 1,
            'message': 'Analyze this statement.',
            'file_id': 456,
          });
          return http.Response(
            jsonEncode({'response': "I've analyzed your statement."}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final chunks = await _repo(
          client,
        ).sendMessage('1', 'Analyze this statement.', fileId: 456).toList();

        expect(chunks, hasLength(2));
        expect(chunks.last.message!.text, "I've analyzed your statement.");
      },
    );

    test('no fileId argument omits the field entirely (never sends a null '
        'file_id, and never sends file_url at all) — text-only messages keep '
        'the exact prior request shape', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('file_id'), isFalse);
        expect(body.containsKey('file_url'), isFalse);
        return http.Response(jsonEncode({'response': 'Hi.'}), 200);
      });

      await _repo(client).sendMessage('1', 'hi').toList();
    });

    test('a file-only send (no typed text) omits "message" entirely rather '
        'than sending an empty string — this is the exact request shape '
        'the backend requires for "user attaches a document with nothing '
        'typed"', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'conversation_id': 16, 'file_id': 6});
        expect(body.containsKey('message'), isFalse);
        expect(body.containsKey('file_url'), isFalse);
        expect(body.containsKey('signed_url'), isFalse);
        expect(body.containsKey('public_url'), isFalse);
        expect(body['file_id'], isA<int>());
        return http.Response(
          jsonEncode({'response': "Got it, I'll take a look."}),
          200,
        );
      });

      final chunks = await _repo(
        client,
      ).sendMessage('16', '', fileId: 6).toList();

      expect(chunks.last.message!.text, "Got it, I'll take a look.");
    });

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

  group('sendMessage 401 retry with refresh', () {
    test('a normal (200) request never calls refresh at all', () async {
      _mockSecureStorage(binding, {'access_token': 'token-123'});
      var refreshCalls = 0;
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'response': 'Hi there.'}), 200);
      });

      final chunks = await _repo(
        client,
        refreshAccessToken: () async {
          refreshCalls++;
          return 'should-not-be-used';
        },
      ).sendMessage('1', 'hi').toList();

      expect(chunks.last.message!.text, 'Hi there.');
      expect(refreshCalls, 0);
    });

    test('a 401 refreshes exactly once, retries the same request with the new '
        'token, and the retry succeeding returns the response normally with '
        'no duplicate delta/done chunks', () async {
      _mockSecureStorage(binding, {'access_token': 'expired-token'});
      final seenTokens = <String>[];
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        seenTokens.add(request.headers['Authorization']!);
        expect(jsonDecode(request.body), {
          'conversation_id': 1,
          'message': 'Analyze this.',
        });
        if (request.headers['Authorization'] == 'Bearer expired-token') {
          return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
        }
        return http.Response(
          jsonEncode({'response': 'Here is the analysis.'}),
          200,
        );
      });

      var refreshCalls = 0;
      final chunks = await _repo(
        client,
        refreshAccessToken: () async {
          refreshCalls++;
          // Mirrors what the real `ApiAuthRepository.refreshAccessToken()`
          // does — writes the new token to secure storage before
          // returning it, which is what `_authHeaders()` re-reads for
          // the retried request below.
          await const FlutterSecureStorage().write(
            key: 'access_token',
            value: 'refreshed-token',
          );
          return 'refreshed-token';
        },
      ).sendMessage('1', 'Analyze this.').toList();

      expect(refreshCalls, 1);
      expect(requestCount, 2);
      expect(seenTokens, ['Bearer expired-token', 'Bearer refreshed-token']);
      // Exactly one delta and one done chunk — a retry must never
      // produce a duplicate assistant response.
      expect(chunks, hasLength(2));
      expect(chunks.first.isDone, isFalse);
      expect(chunks.last.isDone, isTrue);
      expect(chunks.last.message!.text, 'Here is the analysis.');
    });

    test(
      'refresh definitively failing (no valid refresh token) throws '
      'ChatUnauthorizedException and notifies the existing session/auth '
      'controller exactly once — no retry against the chat endpoint',
      () async {
        _mockSecureStorage(binding, {'access_token': 'expired-token'});
        var chatRequestCount = 0;
        final client = MockClient((request) async {
          chatRequestCount++;
          return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
        });

        var sessionExpiredCalls = 0;
        await expectLater(
          _repo(
            client,
            refreshAccessToken: () async => null,
            onSessionExpired: () async {
              sessionExpiredCalls++;
            },
          ).sendMessage('1', 'hi').toList(),
          throwsA(isA<ChatUnauthorizedException>()),
        );

        expect(chatRequestCount, 1);
        // Riverpod dispatches the callback fire-and-forget; give its
        // microtask a turn before asserting it actually ran.
        await Future<void>.delayed(Duration.zero);
        expect(sessionExpiredCalls, 1);
      },
    );

    test('a network failure while refreshing is never treated as an invalid '
        'session — it propagates as a normal connection-style error and '
        'never notifies the session/auth controller', () async {
      _mockSecureStorage(binding, {'access_token': 'expired-token'});
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
      });

      var sessionExpiredCalls = 0;
      await expectLater(
        _repo(
          client,
          refreshAccessToken: () async => throw Exception('socket closed'),
          onSessionExpired: () async {
            sessionExpiredCalls++;
          },
        ).sendMessage('1', 'hi').toList(),
        // Not ChatUnauthorizedException — a plain connection-style
        // failure, same vocabulary every other network error here uses.
        throwsA(isNot(isA<ChatUnauthorizedException>())),
      );

      expect(sessionExpiredCalls, 0);
    });

    test('a second 401 after a successful refresh does not retry again '
        '(prevents an infinite retry loop) and still surfaces as '
        'ChatUnauthorizedException', () async {
      _mockSecureStorage(binding, {'access_token': 'expired-token'});
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        // Every request 401s, even after "refreshing" — the refresh
        // token itself is fine, but the backend keeps rejecting.
        return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
      });

      var refreshCalls = 0;
      await expectLater(
        _repo(
          client,
          refreshAccessToken: () async {
            refreshCalls++;
            return 'refreshed-token';
          },
        ).sendMessage('1', 'hi').toList(),
        throwsA(isA<ChatUnauthorizedException>()),
      );

      // Original request + exactly one retry — never a third attempt.
      expect(requestCount, 2);
      expect(refreshCalls, 1);
    });
  });

  group('getConversations 401 retry with refresh (repository-wide, not '
      'sendMessage-only)', () {
    test(
      'a 401 refreshes once and retries, succeeding transparently',
      () async {
        _mockSecureStorage(binding, {'access_token': 'expired-token'});
        var requestCount = 0;
        final client = MockClient((request) async {
          requestCount++;
          if (request.headers['Authorization'] == 'Bearer expired-token') {
            return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
          }
          return http.Response(jsonEncode({'conversations': <dynamic>[]}), 200);
        });

        var refreshCalls = 0;
        final conversations = await _repo(
          client,
          refreshAccessToken: () async {
            refreshCalls++;
            await const FlutterSecureStorage().write(
              key: 'access_token',
              value: 'refreshed-token',
            );
            return 'refreshed-token';
          },
        ).getConversations();

        expect(conversations, isEmpty);
        expect(refreshCalls, 1);
        expect(requestCount, 2);
      },
    );
  });
}
