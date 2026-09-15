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

/// The suggestions shown above the composer once a conversation has at
/// least one message — plain prompts the AI answers conversationally,
/// never a promise of a specific dashboard-style card in response.
const List<QuickAction> quickActions = [
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
