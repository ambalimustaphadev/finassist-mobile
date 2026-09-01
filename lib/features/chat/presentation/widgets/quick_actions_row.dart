import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../data/models/quick_action.dart';
import 'quick_action_chip.dart';

/// Horizontally scrollable row of quick-prompt shortcuts above the
/// composer. The set of [actions] is contextual — the caller decides
/// which ones make sense given the current conversation state.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.actions,
    required this.onSelect,
  });

  final List<QuickAction> actions;
  final ValueChanged<QuickAction> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        key: const Key('quickActionsList'),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final action = actions[index];
          return QuickActionChip(action: action, onTap: () => onSelect(action));
        },
      ),
    );
  }
}
