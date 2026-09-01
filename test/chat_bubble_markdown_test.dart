import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/theme/app_theme.dart';
import 'package:finassist/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finassist/features/auth/presentation/providers/auth_controller.dart';
import 'package:finassist/features/chat/data/models/chat_message.dart';
import 'package:finassist/features/chat/data/repositories/mock_chat_repository.dart';
import 'package:finassist/features/chat/presentation/providers/chat_controller.dart';
import 'package:finassist/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:finassist/features/dashboard/data/repositories/mock_financial_repository.dart';

import 'support/pump_app.dart';

/// `ChatBubble` (a `ConsumerWidget`) watches `chatControllerProvider`, which
/// constructs a `LocalConversationStore` backed by real
/// `flutter_secure_storage` regardless of which `ChatRepository` is
/// overridden — mock its MethodChannel the same way other chat tests do.
const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return null;
        case 'write':
        case 'delete':
          return null;
        default:
          return null;
      }
    },
  );
}

/// Walks an [InlineSpan] tree (as built by `flutter_markdown`) and collects
/// every [TextStyle] found, so tests can assert on styling regardless of
/// how deeply markdown nests spans for a given piece of text.
List<TextStyle> _collectStyles(InlineSpan root) {
  final styles = <TextStyle>[];
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.style != null) styles.add(span.style!);
      span.children?.forEach(visit);
    }
  }

  visit(root);
  return styles;
}

Future<List<TextStyle>> _pumpAssistantMessageStyles(
  WidgetTester tester,
  String text,
) async {
  _mockSecureStorage(TestWidgetsFlutterBinding.ensureInitialized());

  final message = ChatMessage(
    id: 'msg-1',
    role: ChatMessageRole.assistant,
    text: text,
    timestamp: DateTime(2026, 1, 1),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        chatRepositoryProvider.overrideWithValue(
          MockChatRepository(MockFinancialRepository()),
        ),
        statementFilePickerServiceProvider.overrideWithValue(
          FakeStatementFilePickerService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: ChatBubble(message: message)),
      ),
    ),
  );
  await tester.pump();

  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  return richTexts.expand((r) => _collectStyles(r.text)).toList();
}

void main() {
  testWidgets('bold Markdown (**...**) still renders with bold weight', (
    tester,
  ) async {
    final styles = await _pumpAssistantMessageStyles(
      tester,
      'You spent **₦84,500** this month.',
    );

    expect(styles, isNotEmpty);
    expect(styles.any((s) => s.fontWeight == FontWeight.w700), isTrue);
  });

  testWidgets('inline code (`...`) has no background color', (tester) async {
    final styles = await _pumpAssistantMessageStyles(
      tester,
      'You spent **₦84,500** on `food` this month.',
    );

    expect(styles, isNotEmpty);
    for (final style in styles) {
      expect(
        style.backgroundColor == null ||
            style.backgroundColor == Colors.transparent,
        isTrue,
        reason:
            'Found a non-transparent inline code background: ${style.backgroundColor}',
      );
    }
    // Bold still works alongside the fixed inline-code styling.
    expect(styles.any((s) => s.fontWeight == FontWeight.w700), isTrue);
  });

  testWidgets(
    'a whole sentence wrapped in inline code has no background either',
    (tester) async {
      final styles = await _pumpAssistantMessageStyles(
        tester,
        '`You spent ₦84,500 this month.`',
      );

      expect(styles, isNotEmpty);
      for (final style in styles) {
        expect(
          style.backgroundColor == null ||
              style.backgroundColor == Colors.transparent,
          isTrue,
          reason:
              'Found a non-transparent inline code background: ${style.backgroundColor}',
        );
      }
      expect(find.textContaining('You spent'), findsWidgets);
    },
  );

  testWidgets('plain text with no Markdown renders normally', (tester) async {
    final styles = await _pumpAssistantMessageStyles(
      tester,
      'You spent ₦84,500 this month.',
    );

    expect(styles, isNotEmpty);
    for (final style in styles) {
      expect(
        style.backgroundColor == null ||
            style.backgroundColor == Colors.transparent,
        isTrue,
      );
    }
    expect(find.textContaining('You spent'), findsWidgets);
  });
}
