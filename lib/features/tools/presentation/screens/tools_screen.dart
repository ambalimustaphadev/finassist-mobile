import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/list_action_card.dart';
import '../../../chat/presentation/widgets/chat_drawer.dart';
import '../../../shell/presentation/widgets/main_header_bar.dart';
import 'affordability_calculator_screen.dart';
import 'budget_planner_screen.dart';
import 'compound_growth_calculator_screen.dart';
import 'currency_converter_screen.dart';
import 'loan_calculator_screen.dart';
import 'salary_budget_planner_screen.dart';
import 'savings_calculator_screen.dart';

class _ToolEntry {
  const _ToolEntry({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

final _tools = <_ToolEntry>[
  _ToolEntry(
    icon: Icons.pie_chart_rounded,
    iconColor: AppColors.categoryTransfers,
    title: 'Budget Planner',
    subtitle: '50/30/20 income split',
    builder: (_) => const BudgetPlannerScreen(),
  ),
  _ToolEntry(
    icon: Icons.savings_rounded,
    iconColor: AppColors.accentStrong,
    title: 'Savings Calculator',
    subtitle: 'See how long it will take to reach your goal',
    builder: (_) => const SavingsCalculatorScreen(),
  ),
  _ToolEntry(
    icon: Icons.request_quote_rounded,
    iconColor: AppColors.categoryBills,
    title: 'Loan Calculator',
    subtitle: 'Estimate payments and interest',
    builder: (_) => const LoanCalculatorScreen(),
  ),
  _ToolEntry(
    icon: Icons.currency_exchange_rounded,
    iconColor: AppColors.categoryShopping,
    title: 'Currency Converter',
    subtitle: 'Convert between currencies',
    builder: (_) => const CurrencyConverterScreen(),
  ),
  _ToolEntry(
    icon: Icons.home_work_rounded,
    iconColor: AppColors.categoryFood,
    title: 'Affordability Calculator',
    subtitle: 'What you can comfortably take on',
    builder: (_) => const AffordabilityCalculatorScreen(),
  ),
  _ToolEntry(
    icon: Icons.trending_up_rounded,
    iconColor: AppColors.accent,
    title: 'Investment Calculator',
    subtitle: 'Explore potential returns',
    builder: (_) => const CompoundGrowthCalculatorScreen(),
  ),
  _ToolEntry(
    icon: Icons.account_balance_wallet_rounded,
    iconColor: AppColors.categoryOthers,
    title: 'Salary/Budget Planner',
    subtitle: 'Gross salary to take-home pay',
    builder: (_) => const SalaryBudgetPlannerScreen(),
  ),
];

/// Real, deterministic financial calculators — the AI explains and
/// reasons about money; these compute it exactly the same way every time,
/// independent of any AI call.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const MainHeaderBar(subtitle: BrandTagline()),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(child: _ToolsHeading()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              'Calculate',
                              style: AppTypography.sectionHeading,
                            ),
                          );
                        }
                        final entry = _tools[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.lg,
                          ),
                          child: ListActionCard(
                            icon: entry.icon,
                            iconColor: entry.iconColor,
                            title: entry.title,
                            subtitle: entry.subtitle,
                            onTap: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: entry.builder)),
                          ),
                        );
                      }, childCount: _tools.length + 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolsHeading extends StatelessWidget {
  const _ToolsHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financial tools', style: AppTypography.greeting),
        const SizedBox(height: AppSpacing.xs),
        Text('Simple tools for smarter decisions.', style: AppTypography.body),
      ],
    );
  }
}
