import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/list_action_card.dart';
import '../../../chat/presentation/providers/chat_controller.dart';
import '../../../chat/presentation/widgets/chat_drawer.dart';
import '../../../shell/presentation/providers/shell_providers.dart';
import '../../../shell/presentation/widgets/main_header_bar.dart';
import '../../data/models/quick_shortcut.dart';

final _shortcuts = <QuickShortcut>[
  QuickShortcut(
    icon: Icons.query_stats_rounded,
    iconColor: AppColors.categoryBills,
    title: 'Analyze my spending',
    subtitle: 'Get a clear read on where your money is going',
    prompt: 'Analyze my spending this month.',
  ),
  QuickShortcut(
    icon: Icons.savings_rounded,
    iconColor: AppColors.accentStrong,
    title: 'Create a savings plan',
    subtitle: 'Set and work towards a real goal',
    prompt: 'Help me create a savings plan.',
  ),
  QuickShortcut(
    icon: Icons.calculate_rounded,
    iconColor: AppColors.categoryTransfers,
    title: 'Help me make a budget',
    subtitle: 'Build a realistic monthly budget',
    prompt: 'Help me create a budget.',
  ),
  QuickShortcut(
    icon: Icons.upload_file_rounded,
    iconColor: AppColors.categoryShopping,
    title: 'Understand a financial document',
    subtitle: 'Upload a statement and get insights',
    triggersUpload: true,
  ),
];

/// A lightweight set of shortcuts into a fresh AI conversation — not a
/// second dashboard. Every shortcut starts a new chat and either sends a
/// prompt or opens the attachment flow.
class QuickScreen extends ConsumerWidget {
  const QuickScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const MainHeaderBar(subtitle: BrandTagline()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                children: [
                  Text('Quick actions', style: AppTypography.greeting),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Jump straight into the conversation you need.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  for (final shortcut in _shortcuts) ...[
                    ListActionCard(
                      icon: shortcut.icon,
                      iconColor: shortcut.iconColor,
                      title: shortcut.title,
                      subtitle: shortcut.subtitle,
                      onTap: () => _handleShortcut(context, ref, shortcut),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShortcut(
    BuildContext context,
    WidgetRef ref,
    QuickShortcut shortcut,
  ) {
    final notifier = ref.read(chatControllerProvider.notifier);
    notifier.startNewConversation();
    ref.read(mainTabProvider.notifier).state = chatTabIndex;
    if (shortcut.triggersUpload) {
      notifier.pickAndUploadStatement();
    } else {
      notifier.sendMessage(shortcut.prompt);
    }
  }
}
