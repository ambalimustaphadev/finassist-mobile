import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/local/local_conversation_store.dart';
import 'package:finassist/features/chat/data/models/chat_message.dart';
import 'package:finassist/features/chat/data/models/chat_stream_chunk.dart';
import 'package:finassist/features/chat/data/models/conversation.dart';
import 'package:finassist/features/chat/data/models/statement_analysis_result.dart';
import 'package:finassist/features/chat/data/repositories/chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/chat/presentation/providers/chat_state.dart';
import 'package:finassist/shared/models/uploaded_file_attachment.dart';

import 'support/pump_app.dart';

/// `flutter_secure_storage`'s MethodChannel doesn't exist in a test
/// environment — `ChatController` always constructs a `LocalConversationStore`
/// backed by it (regardless of which `ChatRepository` is under test), so it
/// needs a mock handler here the same way `pump_app.dart`'s widget tests do.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  final values = <String, String>{};
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
        case 'delete':
          values.remove(call.arguments['key']);
          return null;
        default:
          return null;
      }
    },
  );
}

/// A controllable [ChatRepository] test double — each method's failure can
/// be toggled independently, unlike `MockChatRepository` (which always
/// succeeds and exists to drive the UI/demo, not to test error paths).
class _FakeChatRepository implements ChatRepository {
  List<Conversation> conversations = [];
  final Map<String, ConversationDetail> _details = {};
  int _idCounter = 0;

  Object? getConversationsError;
  Object? getConversationError;
  Object? createConversationError;
  Object? deleteConversationError;

  void seedConversation(Conversation conversation, List<ChatMessage> messages) {
    conversations = [...conversations, conversation];
    _details[conversation.id] = ConversationDetail(
      conversation: conversation,
      messages: messages,
    );
  }

  @override
  Future<List<Conversation>> getConversations() async {
    if (getConversationsError != null) throw getConversationsError!;
    return conversations;
  }

  @override
  Future<Conversation> createConversation(String title) async {
    if (createConversationError != null) throw createConversationError!;
    final id = 'fake-${_idCounter++}';
    final now = DateTime.now();
    final conversation = Conversation(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    _details[id] = ConversationDetail(
      conversation: conversation,
      messages: const [],
    );
    conversations = [conversation, ...conversations];
    return conversation;
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    if (getConversationError != null) throw getConversationError!;
    final detail = _details[conversationId];
    if (detail == null) throw const ChatConversationNotFoundException();
    return detail;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    if (deleteConversationError != null) throw deleteConversationError!;
    if (!_details.containsKey(conversationId)) {
      throw const ChatConversationNotFoundException();
    }
    _details.remove(conversationId);
    conversations = conversations.where((c) => c.id != conversationId).toList();
  }

  @override
  Stream<ChatStreamChunk> sendMessage(
    String conversationId,
    String userMessage,
  ) async* {
    final detail = _details[conversationId];
    if (detail == null) throw const ChatConversationNotFoundException();

    final reply = ChatMessage(
      id: 'fake-reply-${_idCounter++}',
      role: ChatMessageRole.assistant,
      text: 'Reply to: $userMessage',
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );

    final userRecord = ChatMessage(
      id: 'fake-user-${_idCounter++}',
      role: ChatMessageRole.user,
      text: userMessage,
      timestamp: DateTime.now(),
      conversationId: conversationId,
    );
    _details[conversationId] = ConversationDetail(
      conversation: detail.conversation.copyWith(updatedAt: DateTime.now()),
      messages: [...detail.messages, userRecord, reply],
    );

    yield ChatStreamChunk.delta(reply.text);
    yield ChatStreamChunk.done(reply);
  }

  @override
  Future<StatementAnalysisResult> analyzeStatement(
    UploadedFileAttachment file,
  ) {
    throw UnimplementedError();
  }

  @override
  String suggestTitle(String userMessage) => 'Fake title';
}

/// Polls [condition] until it's true, up to `maxTries * 10ms` — needed since
/// `ChatController`'s constructor kicks off bootstrap asynchronously.
Future<void> _waitUntil(bool Function() condition, {int maxTries = 100}) async {
  for (var i = 0; i < maxTries; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _mockSecureStorage(binding));
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _secureStorageChannel,
      null,
    );
  });

  ChatController buildController(_FakeChatRepository repo) {
    return ChatController(
      repo,
      FakeStatementFilePickerService(),
      LocalConversationStore(),
      'test-user',
    );
  }

  test(
    'bootstrap with no conversations lands on the loaded empty state, not an error',
    () async {
      final repo = _FakeChatRepository();
      final controller = buildController(repo);

      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );

      expect(
        controller.state.conversationStatus,
        ConversationLoadStatus.loaded,
      );
      expect(controller.state.conversations, isEmpty);
      expect(controller.state.messages, isEmpty);
      expect(controller.state.currentConversationId, isNull);
    },
  );

  test('bootstrap restores the most recently updated conversation', () async {
    final repo = _FakeChatRepository();
    final older = Conversation(
      id: 'c-old',
      title: 'Older',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final newer = Conversation(
      id: 'c-new',
      title: 'Newer',
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    );
    repo.seedConversation(older, const []);
    repo.seedConversation(newer, [
      ChatMessage(
        id: 'm1',
        role: ChatMessageRole.user,
        text: 'Hi from the newer thread',
        timestamp: DateTime(2026, 1, 2),
      ),
    ]);

    final controller = buildController(repo);
    await _waitUntil(
      () =>
          controller.state.conversationStatus != ConversationLoadStatus.loading,
    );

    expect(controller.state.currentConversationId, 'c-new');
    expect(controller.state.messages, hasLength(1));
    expect(controller.state.messages.single.text, 'Hi from the newer thread');
    expect(
      controller.state.conversations.map((c) => c.id),
      containsAll(['c-old', 'c-new']),
    );
  });

  test(
    'bootstrap surfaces an unauthorized failure as a session-expired error',
    () async {
      final repo = _FakeChatRepository()
        ..getConversationsError = const ChatUnauthorizedException();
      final controller = buildController(repo);

      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );

      expect(controller.state.conversationStatus, ConversationLoadStatus.error);
      expect(
        controller.state.conversationError,
        contains('session has expired'),
      );
    },
  );

  test(
    'bootstrap falls back to the local cache on a network failure',
    () async {
      final store = LocalConversationStore();
      final cached = Conversation(
        id: 'cached-1',
        title: 'Cached conversation',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await store.saveConversation('test-user', cached, [
        ChatMessage(
          id: 'm1',
          role: ChatMessageRole.assistant,
          text: 'From the offline cache',
          timestamp: DateTime(2026, 1, 1),
        ),
      ]);

      final repo = _FakeChatRepository()
        ..getConversationsError = Exception('no connection');
      final controller = ChatController(
        repo,
        FakeStatementFilePickerService(),
        store,
        'test-user',
      );

      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );

      expect(
        controller.state.conversationStatus,
        ConversationLoadStatus.loaded,
      );
      expect(controller.state.currentConversationId, 'cached-1');
      expect(controller.state.messages.single.text, 'From the offline cache');
    },
  );

  test(
    'sendMessage on a fresh thread creates a real backend conversation, never a local- id',
    () async {
      final repo = _FakeChatRepository();
      final controller = buildController(repo);
      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );

      await controller.sendMessage('How much did I spend?');
      // isAssistantTyping already flips false once the (empty) assistant
      // bubble appears — the reply text then reveals progressively, so
      // wait for that reveal to finish (both messages present and
      // streamingMessageId cleared) rather than for the typing indicator
      // alone, or for the still-null streamingMessageId from before
      // sending.
      await _waitUntil(
        () =>
            controller.state.messages.length >= 2 &&
            controller.state.streamingMessageId == null,
      );

      expect(controller.state.currentConversationId, isNotNull);
      expect(
        controller.state.currentConversationId,
        isNot(startsWith('local-')),
      );
      expect(repo.conversations, hasLength(1));
      expect(repo.conversations.single.title, 'Fake title');
      expect(
        controller.state.messages.last.text,
        'Reply to: How much did I spend?',
      );
    },
  );

  test(
    'openConversation loads messages from the backend and switches the active thread',
    () async {
      final repo = _FakeChatRepository();
      final first = Conversation(
        id: 'c1',
        title: 'First',
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      );
      final second = Conversation(
        id: 'c2',
        title: 'Second',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      repo.seedConversation(first, const []);
      repo.seedConversation(second, [
        ChatMessage(
          id: 'm1',
          role: ChatMessageRole.user,
          text: 'Message in the second thread',
          timestamp: DateTime(2026, 1, 1),
        ),
      ]);

      final controller = buildController(repo);
      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );
      expect(controller.state.currentConversationId, 'c1');

      await controller.openConversation('c2');
      await _waitUntil(() => controller.state.currentConversationId == 'c2');

      expect(controller.state.messages, hasLength(1));
      expect(
        controller.state.messages.single.text,
        'Message in the second thread',
      );
    },
  );

  test(
    'deleteConversation removes it and clears current if it was active',
    () async {
      final repo = _FakeChatRepository();
      final conversation = Conversation(
        id: 'c1',
        title: 'To delete',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      repo.seedConversation(conversation, const []);

      final controller = buildController(repo);
      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );
      expect(controller.state.currentConversationId, 'c1');

      await controller.deleteConversation('c1');

      expect(controller.state.conversations, isEmpty);
      expect(controller.state.currentConversationId, isNull);
      expect(controller.state.messages, isEmpty);
    },
  );

  test(
    'deleteConversation leaves state untouched when the backend call fails',
    () async {
      final repo = _FakeChatRepository();
      final conversation = Conversation(
        id: 'c1',
        title: 'Keep me',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      repo.seedConversation(conversation, const []);

      final controller = buildController(repo);
      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );

      repo.deleteConversationError = Exception('server error');
      await controller.deleteConversation('c1');

      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.currentConversationId, 'c1');
    },
  );

  group('progressive reveal', () {
    // Long enough that the reveal takes a comfortably observable amount of
    // time (word-chunk pacing in ChatController), so tests can catch it
    // mid-flight instead of racing a near-instant short reply.
    final longMessage = List.generate(40, (i) => 'word$i').join(' ');

    test(
      'the assistant bubble fills in progressively before settling to the full text',
      () async {
        final repo = _FakeChatRepository();
        final controller = buildController(repo);
        await _waitUntil(
          () =>
              controller.state.conversationStatus !=
              ConversationLoadStatus.loading,
        );

        final fullText = 'Reply to: $longMessage';
        unawaited(controller.sendMessage(longMessage));

        // Caught mid-flight: some text has appeared, but not all of it yet.
        await _waitUntil(() => controller.state.streamingMessageId != null);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(controller.state.streamingMessageId, isNotNull);
        final partialText = controller.state.messages.last.text;
        expect(partialText, isNotEmpty);
        expect(partialText.length, lessThan(fullText.length));
        expect(fullText.startsWith(partialText), isTrue);

        await _waitUntil(
          () => controller.state.streamingMessageId == null,
          maxTries: 400,
        );
        expect(controller.state.messages.last.text, fullText);
        // The reveal doesn't add or drop any messages — still exactly one
        // user message and one assistant reply.
        expect(controller.state.messages, hasLength(2));
      },
    );

    test(
      'sending another message completes the previous reveal in full, without duplicating it',
      () async {
        final repo = _FakeChatRepository();
        final controller = buildController(repo);
        await _waitUntil(
          () =>
              controller.state.conversationStatus !=
              ConversationLoadStatus.loading,
        );

        final firstFullText = 'Reply to: $longMessage';
        unawaited(controller.sendMessage(longMessage));
        await _waitUntil(() => controller.state.streamingMessageId != null);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        // Confirm it's genuinely still mid-reveal before interrupting it.
        expect(controller.state.messages.last.text, isNot(firstFullText));

        await controller.sendMessage('Second message');
        await _waitUntil(
          () =>
              controller.state.messages.length >= 4 &&
              controller.state.streamingMessageId == null,
          maxTries: 400,
        );

        final texts = controller.state.messages.map((m) => m.text).toList();
        expect(texts, hasLength(4));
        expect(texts[1], firstFullText); // completed in full, not left partial
        expect(texts.last, 'Reply to: Second message');
        expect(
          texts.where((t) => t == firstFullText),
          hasLength(1),
        ); // no duplicate
      },
    );

    test(
      'opening a different conversation mid-reveal cancels it without leaking into the new one',
      () async {
        // Starts with no conversations at all, so `sendMessage` below
        // creates a brand-new one (not "other") and makes it current —
        // otherwise, if "other" were seeded before construction, bootstrap
        // would auto-restore it as the (already) current conversation and
        // `openConversation('other')` would be a no-op, not a real switch.
        final repo = _FakeChatRepository();
        final controller = buildController(repo);
        await _waitUntil(
          () =>
              controller.state.conversationStatus !=
              ConversationLoadStatus.loading,
        );

        unawaited(controller.sendMessage(longMessage));
        await _waitUntil(() => controller.state.streamingMessageId != null);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(controller.state.streamingMessageId, isNotNull);
        final revealingConversationId = controller.state.currentConversationId;

        // "other" now exists (e.g. fetched from the backend elsewhere) —
        // distinct from the conversation currently mid-reveal.
        final other = Conversation(
          id: 'other',
          title: 'Other',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );
        repo.seedConversation(other, [
          ChatMessage(
            id: 'm1',
            role: ChatMessageRole.user,
            text: 'Hello from other',
            timestamp: DateTime(2026, 1, 1),
          ),
        ]);

        await controller.openConversation('other');
        await _waitUntil(
          () => controller.state.currentConversationId == 'other',
        );

        expect(
          controller.state.currentConversationId,
          isNot(revealingConversationId),
        );
        expect(controller.state.streamingMessageId, isNull);
        expect(controller.state.messages, hasLength(1));
        expect(controller.state.messages.single.text, 'Hello from other');

        // Give any stray reveal timer a chance to fire and confirm it
        // doesn't resurrect itself into the now-current conversation.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(controller.state.currentConversationId, 'other');
        expect(controller.state.messages, hasLength(1));
        expect(controller.state.messages.single.text, 'Hello from other');
      },
    );

    test(
      'starting a new conversation mid-reveal resets cleanly, no exceptions',
      () async {
        final repo = _FakeChatRepository();
        final controller = buildController(repo);
        await _waitUntil(
          () =>
              controller.state.conversationStatus !=
              ConversationLoadStatus.loading,
        );

        unawaited(controller.sendMessage(longMessage));
        await _waitUntil(() => controller.state.streamingMessageId != null);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        controller.startNewConversation();

        expect(controller.state.currentConversationId, isNull);
        expect(controller.state.messages, isEmpty);
        expect(controller.state.streamingMessageId, isNull);

        // Let any stray timer fire; it must not throw or repopulate messages.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(controller.state.messages, isEmpty);
      },
    );

    test('disposing the controller mid-reveal does not throw', () async {
      final repo = _FakeChatRepository();
      final controller = buildController(repo);
      await _waitUntil(
        () =>
            controller.state.conversationStatus !=
            ConversationLoadStatus.loading,
      );

      unawaited(controller.sendMessage(longMessage));
      await _waitUntil(() => controller.state.streamingMessageId != null);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      controller.dispose();

      // The in-flight reveal's next scheduled tick fires after disposal —
      // it must find the cancelled token and quietly return instead of
      // writing to `state` (which would throw on a disposed notifier).
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
  });
}
