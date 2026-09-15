import 'dart:math';

import '../../../../shared/models/uploaded_file_attachment.dart';
import '../models/chat_message.dart';
import '../models/chat_stream_chunk.dart';
import '../models/conversation.dart';
import 'chat_repository.dart';

/// In-memory mock of [ChatRepository], including conversation CRUD, so it
/// can stand in for the real backend's `User -> Conversations -> Messages`
/// contract in tests and local dev. Response latency is simulated here
/// (not in the controller) so a future `ApiChatRepository` can simply
/// replace this class without the chat controller changing at all. Every
/// reply is plain chat text — this mock never fabricates a financial
/// dashboard card (balances, category breakdowns, recurring-payment
/// lists, etc.), matching what the real backend actually returns.
class MockChatRepository implements ChatRepository {
  MockChatRepository();

  final Random _random = Random();
  int _idCounter = 0;
  int _conversationIdCounter = 0;

  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messagesByConversation = {};

  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  Future<void> _simulateDelay() {
    final ms = 800 + _random.nextInt(700); // 800-1500ms
    return Future.delayed(Duration(milliseconds: ms));
  }

  @override
  Future<List<Conversation>> getConversations() async {
    final list = _conversations.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<Conversation> createConversation(String title) async {
    final id = 'mock-${_conversationIdCounter++}';
    final now = DateTime.now();
    final conversation = Conversation(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    _conversations[id] = conversation;
    _messagesByConversation[id] = [];
    return conversation;
  }

  @override
  Future<ConversationDetail> getConversation(String conversationId) async {
    final conversation = _conversations[conversationId];
    if (conversation == null) {
      throw const ChatConversationNotFoundException();
    }
    return ConversationDetail(
      conversation: conversation,
      messages: List.unmodifiable(
        _messagesByConversation[conversationId] ?? const [],
      ),
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    if (!_conversations.containsKey(conversationId)) {
      throw const ChatConversationNotFoundException();
    }
    _conversations.remove(conversationId);
    _messagesByConversation.remove(conversationId);
  }

  @override
  Stream<ChatStreamChunk> sendMessage(
    String conversationId,
    String userMessage, {
    int? fileId,
  }) async* {
    final conversation = _conversations[conversationId];
    if (conversation == null) {
      throw const ChatConversationNotFoundException();
    }

    final userRecord = ChatMessage(
      id: _nextId('mock-user'),
      role: ChatMessageRole.user,
      text: userMessage,
      timestamp: DateTime.now(),
      conversationId: conversationId,
      // Mirrors the real `ApiChatRepository`'s restoration of a file
      // reference from a message's stored content — without this, a
      // reopened conversation would silently lose its attachment even
      // though it was really sent with one.
      fileAttachment: fileId == null
          ? null
          : UploadedFileAttachment(
              fileName: 'Attached document',
              fileId: fileId,
            ),
    );

    final generated = await _generateResponse(userMessage);
    final reply = ChatMessage(
      id: generated.id,
      role: generated.role,
      text: generated.text,
      timestamp: generated.timestamp,
      conversationId: conversationId,
      followUpSuggestions: generated.followUpSuggestions,
    );

    _messagesByConversation.putIfAbsent(conversationId, () => []).addAll([
      userRecord,
      reply,
    ]);
    _conversations[conversationId] = conversation.copyWith(
      updatedAt: DateTime.now(),
    );

    yield ChatStreamChunk.delta(reply.text);
    yield ChatStreamChunk.done(reply);
  }

  Future<ChatMessage> _generateResponse(String userMessage) async {
    final message = userMessage.toLowerCase();

    if (message.contains('save') ||
        message.contains('saving') ||
        message.contains('cut') ||
        message.contains('reduce')) {
      await _simulateDelay();
      return _buildSavingsResponse();
    }

    if (message.contains('budget')) {
      await _simulateDelay();
      return _buildBudgetResponse(userMessage);
    }

    await _simulateDelay();
    return _buildFallbackResponse();
  }

  @override
  String suggestTitle(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('budget')) return 'Budget planning';
    if (message.contains('statement') || message.contains('upload')) {
      return 'Statement review';
    }
    if (message.contains('save') ||
        message.contains('saving') ||
        message.contains('reduce') ||
        message.contains('cut')) {
      return 'Saving money';
    }
    if (message.contains('spend') || message.contains('spending')) {
      return 'Spending analysis';
    }
    return 'Monthly finances';
  }

  ChatMessage _buildSavingsResponse() {
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'A good starting point is to identify your essential expenses '
          'first, then set a fixed savings amount before spending on '
          'discretionary items. Automating a transfer to savings right '
          'after you get paid also makes it easier to stay consistent.\n\n'
          'Upload your bank statement and I can point out exactly where '
          "you're overspending.",
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _buildBudgetResponse(String originalMessage) {
    final income = _extractIncomeAmount(originalMessage);
    if (income != null && income > 0) {
      final essentials = income * 0.5;
      final lifestyle = income * 0.3;
      final savings = income * 0.2;
      return ChatMessage(
        id: _nextId('msg'),
        role: ChatMessageRole.assistant,
        text:
            'With ₦${income.toStringAsFixed(0)} monthly income, here\'s a '
            'practical starting point:\n\n'
            '₦${essentials.toStringAsFixed(0)} (50%) on essentials like rent and bills\n'
            '₦${lifestyle.toStringAsFixed(0)} (30%) on lifestyle spending\n'
            '₦${savings.toStringAsFixed(0)} (20%) saved or invested\n\n'
            'Upload your statement and I can tailor this to your real spending.',
        timestamp: DateTime.now(),
      );
    }
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'A simple starting framework is the 50/30/20 rule: 50% on '
          'essentials, 30% on lifestyle spending, and 20% saved or '
          'invested. Tell me your income and I can break it down, or '
          'upload your statement for a plan based on your real spending.',
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _buildFallbackResponse() {
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'I can help with budgeting, saving tips, or analyzing your '
          'bank statement — what would you like to do?',
      timestamp: DateTime.now(),
    );
  }

  double? _extractIncomeAmount(String message) {
    final match = RegExp(r'(\d[\d,]*)').firstMatch(message.replaceAll('₦', ''));
    if (match == null) return null;
    final digits = match.group(1)!.replaceAll(',', '');
    return double.tryParse(digits);
  }
}
