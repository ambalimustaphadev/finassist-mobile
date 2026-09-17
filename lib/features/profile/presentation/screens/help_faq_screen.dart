import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

class _FaqCategory {
  const _FaqCategory(this.title, this.items);
  final String title;
  final List<_FaqItem> items;
}

const _categories = [
  _FaqCategory('Getting started', [
    _FaqItem(
      'What is FinAssist?',
      'FinAssist is an AI financial companion that helps you make sense of '
          'money through conversation. You can ask questions, understand '
          'financial concepts, explore decisions and work with financial '
          'information you choose to share.',
    ),
    _FaqItem(
      'How does FinAssist work?',
      "You chat with FinAssist the same way you'd message someone "
          'knowledgeable about money. Ask a question, share a document if '
          "it's relevant, and FinAssist responds using what you've told it "
          "and what you've shared.",
    ),
    _FaqItem(
      'What can I ask FinAssist?',
      'Anything about money: budgeting, saving, debt, investing concepts, '
          "or questions about a document you've uploaded. If FinAssist "
          'needs more information to answer well, it will ask.',
    ),
  ]),
  _FaqCategory('AI & financial questions', [
    _FaqItem(
      'Can FinAssist analyse a financial document?',
      'Yes. Upload a bank statement or financial document in a '
          'conversation and FinAssist can help you understand what\'s in '
          'it.',
    ),
    _FaqItem(
      'How should I use FinAssist for financial decisions?',
      'Treat FinAssist as a starting point for understanding your '
          "options, not a final answer. For major decisions, it's worth "
          'checking with a qualified professional too.',
    ),
    _FaqItem(
      'Can FinAssist make mistakes?',
      'Yes. FinAssist can help you understand information and think '
          'through financial questions, but its answers can sometimes be '
          'incomplete or incorrect. Check important information before '
          'making a financial decision.',
    ),
  ]),
  _FaqCategory('Documents', [
    _FaqItem(
      'Why did a document upload fail?',
      "This usually happens with an unsupported file type, a file that's "
          'too large, or a temporary connection issue. FinAssist accepts '
          'PDF, CSV, XLS, XLSX, JPG and PNG files.',
    ),
  ]),
  _FaqCategory('Account', [
    _FaqItem(
      'How do I change my password?',
      "Changing your password from the app isn't available yet. Reach "
          'out through Contact support if you need help with your '
          'account.',
    ),
    _FaqItem(
      'How do I change my account information?',
      'Open Profile, then Personal information, to update your first and '
          'last name.',
    ),
  ]),
  _FaqCategory('Privacy & data', [
    _FaqItem(
      'How does FinAssist handle my information?',
      'Open Profile, then Privacy, for a plain language explanation of '
          "what FinAssist stores and how it's used.",
    ),
  ]),
  _FaqCategory('Troubleshooting', [
    _FaqItem(
      "Why can't FinAssist access something on my device?",
      'FinAssist only asks for access it actually needs, like your '
          'camera for a profile photo. You can review this under Manage '
          'app permissions.',
    ),
    _FaqItem(
      'Why am I not receiving notifications?',
      "Check that notifications are turned on both in FinAssist's own "
          "settings and in your device's system settings.",
    ),
  ]),
];

/// A real help center: searchable, categorized questions with natural
/// answers, rather than a flat unstructured list.
class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final _searchController = TextEditingController();
  final Set<String> _expanded = {};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final categories = query.isEmpty
        ? _categories
        : _categories
              .map(
                (category) => _FaqCategory(
                  category.title,
                  category.items
                      .where(
                        (item) =>
                            item.question.toLowerCase().contains(query) ||
                            item.answer.toLowerCase().contains(query),
                      )
                      .toList(),
                ),
              )
              .where((category) => category.items.isNotEmpty)
              .toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text('Help & FAQ', style: AppTypography.screenTitle(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _searchController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.body(context).copyWith(
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for a topic',
                  hintStyle: AppTypography.body(context).copyWith(
                    color: context.colors.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.textMuted,
                  ),
                  filled: true,
                  fillColor: context.colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        'No results for "$_query".',
                        style: AppTypography.body(context).copyWith(
                          color: context.colors.textMuted,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      children: [
                        for (final category in categories) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                              top: AppSpacing.lg,
                            ),
                            child: Text(
                              category.title,
                              style: AppTypography.bodyMedium(context).copyWith(
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          for (final item in category.items)
                            _FaqTile(
                              item: item,
                              expanded: _expanded.contains(
                                '${category.title}|${item.question}',
                              ),
                              onTap: () => setState(() {
                                final key =
                                    '${category.title}|${item.question}';
                                if (!_expanded.remove(key)) {
                                  _expanded.add(key);
                                }
                              }),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final _FaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: AppTypography.bodyMedium(context),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: context.colors.textMuted,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(item.answer, style: AppTypography.body(context)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
