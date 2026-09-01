import 'package:flutter/material.dart';

/// A tappable shortcut above the chat composer that inserts a canned
/// prompt into the conversation — or, for [triggersUpload], opens the file
/// picker directly instead of sending a text message.
class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.prompt,
    this.triggersUpload = false,
  });

  final String label;
  final IconData icon;
  final String prompt;

  /// When true, selecting this action opens the statement file picker
  /// instead of sending [prompt] as a chat message.
  final bool triggersUpload;
}

const List<QuickAction> _beforeAnalysisActions = [
  QuickAction(
    label: 'Analyze my spending',
    icon: Icons.query_stats_rounded,
    prompt: 'Analyze my spending this month.',
  ),
  QuickAction(
    label: 'Create a budget',
    icon: Icons.calculate_rounded,
    prompt: 'Can you help me create a budget?',
  ),
  QuickAction(
    label: 'Find ways to save',
    icon: Icons.savings_rounded,
    prompt: 'What are some ways I can save money?',
  ),
  QuickAction(
    label: 'Upload statement',
    icon: Icons.upload_file_rounded,
    prompt: '',
    triggersUpload: true,
  ),
];

const List<QuickAction> _afterAnalysisActions = [
  QuickAction(
    label: 'Spending summary',
    icon: Icons.pie_chart_rounded,
    prompt: 'Give me a summary of my spending this month.',
  ),
  QuickAction(
    label: 'Recurring payments',
    icon: Icons.event_repeat_rounded,
    prompt: 'Can you show me my recurring payments?',
  ),
  QuickAction(
    label: 'Where can I cut down?',
    icon: Icons.trending_down_rounded,
    prompt: 'Where can I cut down on spending?',
  ),
  QuickAction(
    label: 'Compare my spending',
    icon: Icons.compare_arrows_rounded,
    prompt: 'Compare my spending with last month.',
  ),
];

/// The quick-action suggestions change once a statement has been analyzed,
/// so the interface feels like it's actually paying attention.
List<QuickAction> quickActionsFor({required bool hasFinancialData}) {
  return hasFinancialData ? _afterAnalysisActions : _beforeAnalysisActions;
}
