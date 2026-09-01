import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/greeting_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/chat_cta_button.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/financial_illustration.dart';
import '../widgets/floating_ai_button.dart';
import '../widgets/spending_overview_card.dart';
import '../widgets/statement_card.dart';

/// The app's primary tab shell. Home and Profile share this single screen
/// and its [AppBottomNavBar] — Profile is swapped in as the active tab's
/// content via [dashboardTabProvider] rather than pushed as a separate
/// route, so the bottom nav (and Profile's active-tab highlight) stays on
/// screen exactly like the other primary destinations would.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(dashboardTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNavBar(),
      body: activeTab == profileNavIndex
          ? const ProfileScreen()
          : const _DashboardHomeBody(),
    );
  }
}

class _DashboardHomeBody extends StatelessWidget {
  const _DashboardHomeBody();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Column(
          children: [
            _DashboardFixedHeader(),
            Expanded(child: _DashboardScrollableBody()),
          ],
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: FloatingAIButton(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.chat),
          ),
        ),
      ],
    );
  }
}

/// Menu, greeting and subtitle — stays visible while the content below it
/// scrolls, so the user never loses their bearing on the dashboard.
class _DashboardFixedHeader extends ConsumerWidget {
  const _DashboardFixedHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentTimeProvider).valueOrNull ?? DateTime.now();
    final greeting = GreetingService.greetingFor(now);
    final firstName = ref.watch(
      authControllerProvider.select((state) => state.user?.firstName),
    );
    final displayName = (firstName == null || firstName.isEmpty)
        ? 'there'
        : firstName;

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardHeader(),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: AppTypography.greeting,
                          children: [
                            TextSpan(text: '$greeting,\n'),
                            TextSpan(
                              text: '$displayName ',
                              style: const TextStyle(color: AppColors.accent),
                            ),
                            const TextSpan(text: '👋'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        "Here's your financial overview",
                        style: AppTypography.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const FinancialIllustration(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Statement, spending overview, insights and the chat CTA — everything
/// that scrolls beneath the fixed header.
class _DashboardScrollableBody extends ConsumerWidget {
  const _DashboardScrollableBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statement = ref.watch(statementProvider);
    final summary = ref.watch(spendingSummaryProvider);
    final categories = ref.watch(spendingCategoriesProvider);
    final insights = ref.watch(insightsProvider);

    return ListView(
      key: const Key('dashboardScrollView'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        // Extra clearance so the floating AI button never sits on top of
        // the chat CTA once the user scrolls to the bottom.
        AppSpacing.xxxl + AppSpacing.huge,
      ),
      children: [
        statement.when(
          data: (value) => StatementCard(
            statement: value,
            onTap: () => _showSyncedMessage(context),
          ),
          loading: () => const _CardPlaceholder(height: 92),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (summary.hasValue && categories.hasValue)
          SpendingOverviewCard(
            summary: summary.value!,
            categories: categories.value!,
          )
        else
          const _CardPlaceholder(height: 320),
        const SizedBox(height: AppSpacing.lg),
        insights.when(
          data: (value) => AIInsightsCard(insights: value),
          loading: () => const _CardPlaceholder(height: 220),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ChatCTAButton(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.chat),
        ),
      ],
    );
  }

  void _showSyncedMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            'Your statement is synced and up to date.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSubtle),
      ),
    );
  }
}
