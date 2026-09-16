import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../track/presentation/screens/subscription_overview_screen.dart';
import '../../../tools/presentation/screens/tools_screen.dart';
import '../providers/shell_providers.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/quick_chat_fab.dart';

/// FinAssist's primary tab shell — Chat, Track, Tools and Profile all
/// share this single screen and its [AppBottomNavBar]; the active tab's
/// content is swapped in via [mainTabProvider] rather than pushed as a
/// separate route, so the bottom nav stays on screen no matter which tab
/// is active, including throughout an active AI conversation. Chat is the
/// default tab — FinAssist's landing destination, not one of four equal
/// peers. A small [QuickChatFab] floats above the nav bar on every
/// non-Chat tab for one-tap return to the conversation.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(mainTabProvider);

    return Scaffold(
      key: const Key('mainShellScreen'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNavBar(),
      floatingActionButton: activeTab == chatTabIndex
          ? null
          : const QuickChatFab(),
      body: switch (activeTab) {
        trackTabIndex => const SubscriptionOverviewScreen(),
        toolsTabIndex => const ToolsScreen(),
        profileTabIndex => const ProfileScreen(),
        _ => const ChatScreen(),
      },
    );
  }
}
