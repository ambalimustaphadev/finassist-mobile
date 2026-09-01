import 'dart:math';

import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/models/spending_category_type.dart';
import '../../../../shared/models/uploaded_file_attachment.dart';
import '../../../dashboard/data/repositories/financial_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_stream_chunk.dart';
import '../models/conversation.dart';
import '../models/recurring_payment.dart';
import '../models/statement_analysis_result.dart';
import 'chat_repository.dart';

enum _ResponseWeight { simple, financial, analysis }

/// In-memory mock of [ChatRepository], including conversation CRUD, so it
/// can stand in for the real backend's `User -> Conversations -> Messages`
/// contract in tests and local dev. Generates replies from the same
/// [FinancialRepository] the dashboard uses, so figures stay consistent
/// across both screens. Response latency is simulated here (not in the
/// controller) so a future `ApiChatRepository` can simply replace this
/// class without the chat controller changing at all.
class MockChatRepository implements ChatRepository {
  MockChatRepository(this._financialRepository);

  final FinancialRepository _financialRepository;
  final Random _random = Random();
  int _idCounter = 0;
  int _conversationIdCounter = 0;

  /// Whether a statement has been analyzed in this (mock) session — a
  /// single-session simplification stands in for the real backend, which
  /// will eventually let an AI agent decide this per conversation.
  bool _hasFinancialData = false;

  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messagesByConversation = {};

  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  static const int _mockTransactionCount = 86;

  static const List<RecurringPayment> _recurringPayments = [
    RecurringPayment(
      name: 'Netflix Subscription',
      amount: 4500,
      frequency: 'Monthly',
    ),
    RecurringPayment(
      name: 'Spotify Premium',
      amount: 1900,
      frequency: 'Monthly',
    ),
    RecurringPayment(name: 'DSTV Compact', amount: 15700, frequency: 'Monthly'),
    RecurringPayment(
      name: 'Gym Membership',
      amount: 5400,
      frequency: 'Monthly',
    ),
  ];

  Future<void> _simulateDelay(_ResponseWeight weight) {
    final int ms = switch (weight) {
      _ResponseWeight.simple => 800 + _random.nextInt(700), // 800-1500ms
      _ResponseWeight.financial => 1200 + _random.nextInt(800), // 1200-2000ms
      _ResponseWeight.analysis => 2000 + _random.nextInt(2000), // 2000-4000ms
    };
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
    String? fileUrl,
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
    );

    final generated = await _generateResponse(userMessage);
    final reply = ChatMessage(
      id: generated.id,
      role: generated.role,
      text: generated.text,
      timestamp: generated.timestamp,
      conversationId: conversationId,
      messageType: generated.messageType,
      highlights: generated.highlights,
      categoryBreakdown: generated.categoryBreakdown,
      recurringPayments: generated.recurringPayments,
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
    final hasFinancialData = _hasFinancialData;

    if (message.contains('recurring') || message.contains('subscription')) {
      await _simulateDelay(_ResponseWeight.financial);
      return hasFinancialData
          ? _buildRecurringPaymentsResponse()
          : _buildUploadPromptResponse();
    }

    if (message.contains('spent the most') ||
        message.contains('spend the most') ||
        message.contains('spending the most') ||
        message.contains('where am i spending') ||
        message.contains('where do i spend') ||
        message.contains('breakdown') ||
        message.contains('summary') ||
        message.contains('analyz') ||
        message.contains('analys') ||
        message.contains('biggest') ||
        message.contains('transaction')) {
      await _simulateDelay(_ResponseWeight.financial);
      return hasFinancialData
          ? await _buildTopCategoryResponse()
          : _buildUploadPromptResponse();
    }

    if (message.contains('unnecessary')) {
      await _simulateDelay(_ResponseWeight.financial);
      return hasFinancialData
          ? _buildUnnecessaryExpensesResponse()
          : _buildUploadPromptResponse();
    }

    if (message.contains('compare')) {
      await _simulateDelay(_ResponseWeight.financial);
      return hasFinancialData
          ? await _buildComparisonResponse()
          : _buildUploadPromptResponse();
    }

    if (message.contains('save') ||
        message.contains('saving') ||
        message.contains('cut') ||
        message.contains('reduce')) {
      if (hasFinancialData) {
        await _simulateDelay(_ResponseWeight.financial);
        return await _buildSavingsResponse();
      }
      await _simulateDelay(_ResponseWeight.simple);
      return _buildGenericSavingsResponse();
    }

    if (message.contains('budget')) {
      if (hasFinancialData) {
        await _simulateDelay(_ResponseWeight.financial);
        return _buildBudgetResponse();
      }
      await _simulateDelay(_ResponseWeight.simple);
      return _buildGenericBudgetResponse(userMessage);
    }

    await _simulateDelay(_ResponseWeight.simple);
    return hasFinancialData
        ? _buildFallbackResponse()
        : _buildGenericFallbackResponse();
  }

  @override
  Future<StatementAnalysisResult> analyzeStatement(
    UploadedFileAttachment file,
  ) async {
    await _simulateDelay(_ResponseWeight.analysis);
    _hasFinancialData = true;

    final summary = await _financialRepository.getSpendingSummary();
    final breakdown = await _financialRepository.getCategoryBreakdown(
      SpendingCategoryType.foodAndDining,
    );
    final statement = await _financialRepository.getStatement();
    final recurringTotal = _recurringPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );

    final message = ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          "I've finished analyzing your statement. 🔎\n\n"
          'You spent ${summary.totalAmount.toNaira()} this month across '
          '$_mockTransactionCount transactions.\n\n'
          'Your biggest spending category was ${breakdown.category.label}, '
          'at ${breakdown.amount.toNaira()}.\n\n'
          'I also found ${_recurringPayments.length} recurring payments '
          'totaling ${recurringTotal.toNaira()}.\n\n'
          'What would you like to know?',
      timestamp: DateTime.now(),
      highlights: [
        summary.totalAmount.toNaira(),
        '$_mockTransactionCount transactions',
        breakdown.category.label,
        breakdown.amount.toNaira(),
        '${_recurringPayments.length} recurring payments',
        recurringTotal.toNaira(),
      ],
      followUpSuggestions: const [
        'Where can I cut down?',
        'Show biggest expenses',
        'Create a budget',
      ],
    );

    return StatementAnalysisResult(
      message: message,
      periodStart: statement.periodStart,
      periodEnd: statement.periodEnd,
    );
  }

  @override
  String suggestTitle(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('budget')) return 'Budget planning';
    if (message.contains('recurring') || message.contains('subscription')) {
      return 'Recurring payments';
    }
    if (message.contains('statement') || message.contains('upload')) {
      return 'Statement review';
    }
    if (message.contains('save') ||
        message.contains('saving') ||
        message.contains('reduce') ||
        message.contains('cut')) {
      return 'Saving money';
    }
    if (message.contains('spend') ||
        message.contains('spending') ||
        message.contains('summary') ||
        message.contains('analyz') ||
        message.contains('compare')) {
      return 'Spending analysis';
    }
    return 'Monthly finances';
  }

  Future<ChatMessage> _buildTopCategoryResponse() async {
    final breakdown = await _financialRepository.getCategoryBreakdown(
      SpendingCategoryType.foodAndDining,
    );
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'You spent the most on ${breakdown.category.label} this month — '
          '${breakdown.amount.toNaira()}, or about '
          '${breakdown.percentageOfTotal.toPercentage()} of your total spending.\n\n'
          "If you're looking to reduce expenses, this is probably the first "
          "category I'd review.",
      timestamp: DateTime.now(),
      messageType: ChatMessageType.categoryBreakdown,
      highlights: [
        breakdown.category.label,
        breakdown.amount.toNaira(),
        breakdown.percentageOfTotal.toPercentage(),
      ],
      categoryBreakdown: breakdown,
      followUpSuggestions: const [
        'Show transactions',
        'Find ways to reduce this',
        'Compare with last month',
      ],
    );
  }

  ChatMessage _buildRecurringPaymentsResponse() {
    final total = _recurringPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'You have ${_recurringPayments.length} recurring payments '
          'totaling ${total.toNaira()} this month.',
      timestamp: DateTime.now(),
      messageType: ChatMessageType.recurringPayments,
      highlights: [total.toNaira()],
      recurringPayments: _recurringPayments,
      followUpSuggestions: const [
        'Show all subscriptions',
        'Find unnecessary payments',
        'How much can I save?',
      ],
    );
  }

  Future<ChatMessage> _buildSavingsResponse() async {
    final breakdown = await _financialRepository.getCategoryBreakdown(
      SpendingCategoryType.foodAndDining,
    );
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'Based on your statement, ${breakdown.category.label} is your '
          "biggest opportunity — you're 18% above last month there. "
          'Cutting back to your usual pace could save you roughly '
          '₦25,000 this month. Cancelling one unused subscription could '
          'add another ₦4,500–₦15,700.',
      timestamp: DateTime.now(),
      highlights: ['18%', '₦25,000', '₦4,500–₦15,700'],
    );
  }

  ChatMessage _buildGenericSavingsResponse() {
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

  ChatMessage _buildUnnecessaryExpensesResponse() {
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'A few things stand out: your DSTV Compact plan '
          '(₦15,700/month) is rarely used based on your viewing pattern, '
          "and you're paying for both Netflix and Spotify while dining "
          'out 18% more than usual. Trimming these could free up '
          '₦20,000+ a month.',
      timestamp: DateTime.now(),
      highlights: ['₦15,700/month', '₦20,000+'],
    );
  }

  Future<ChatMessage> _buildComparisonResponse() async {
    final summary = await _financialRepository.getSpendingSummary();
    final breakdown = await _financialRepository.getCategoryBreakdown(
      SpendingCategoryType.foodAndDining,
    );
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'Compared to last month, your overall spending is up '
          '${summary.comparisonPercentage.toPercentage()}.\n\n'
          'The biggest shift was in ${breakdown.category.label}, which rose '
          "noticeably — that's the main driver behind the increase. Bills "
          'and Transfers stayed roughly flat.',
      timestamp: DateTime.now(),
      highlights: [
        summary.comparisonPercentage.toPercentage(),
        breakdown.category.label,
      ],
      followUpSuggestions: const [
        'Where can I cut down?',
        'Show biggest expenses',
      ],
    );
  }

  ChatMessage _buildBudgetResponse() {
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          "Here's a simple starting budget based on your statement: "
          '50% on essentials like bills and rent, 30% on lifestyle '
          'categories like Food & Dining and Shopping, and 20% saved or '
          'invested. For your ₦485,200 income this would mean capping '
          'Food & Dining closer to ₦120,000 a month.',
      timestamp: DateTime.now(),
      highlights: ['50%', '30%', '20%', '₦485,200', '₦120,000'],
    );
  }

  ChatMessage _buildGenericBudgetResponse(String originalMessage) {
    final income = _extractIncomeAmount(originalMessage);
    if (income != null && income > 0) {
      final essentials = income * 0.5;
      final lifestyle = income * 0.3;
      final savings = income * 0.2;
      return ChatMessage(
        id: _nextId('msg'),
        role: ChatMessageRole.assistant,
        text:
            'With ${income.toNaira()} monthly income, here\'s a practical '
            'starting point:\n\n'
            '${essentials.toNaira()} (50%) on essentials like rent and bills\n'
            '${lifestyle.toNaira()} (30%) on lifestyle spending\n'
            '${savings.toNaira()} (20%) saved or invested\n\n'
            'Upload your statement and I can tailor this to your real spending.',
        timestamp: DateTime.now(),
        highlights: [
          income.toNaira(),
          essentials.toNaira(),
          lifestyle.toNaira(),
          savings.toNaira(),
        ],
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
      highlights: ['50/30/20'],
    );
  }

  ChatMessage _buildUploadPromptResponse() {
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          'I can analyze that for you. Upload your bank statement and '
          "I'll look at your spending patterns, categories, and recurring "
          'payments.',
      timestamp: DateTime.now(),
      messageType: ChatMessageType.uploadPrompt,
    );
  }

  ChatMessage _buildFallbackResponse() {
    return ChatMessage(
      id: _nextId('msg'),
      role: ChatMessageRole.assistant,
      text:
          "I've got your statement for May 1 – May 31, 2024 handy — ask "
          'me about your top spending categories, recurring payments, or '
          'ways to save.',
      timestamp: DateTime.now(),
    );
  }

  ChatMessage _buildGenericFallbackResponse() {
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
