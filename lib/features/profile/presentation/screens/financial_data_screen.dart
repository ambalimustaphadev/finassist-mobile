import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../providers/profile_finance_controller.dart';

/// A summary of the financial data FinAssist has actually extracted from
/// this user's uploaded statements — real metadata only, never a fake
/// balance or transaction count.
class FinancialDataScreen extends ConsumerWidget {
  const FinancialDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileFinanceControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Financial data', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: state.isLoadingStatements
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2.2,
                ),
              )
            : state.hasFinancialData
            ? _FinancialDataSummary(state: state)
            : const _NoFinancialData(),
      ),
    );
  }
}

class _NoFinancialData extends StatelessWidget {
  const _NoFinancialData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.textMuted,
              size: 56,
              iconSize: 26,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No financial data yet', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Upload a bank statement to provide financial data to FinAssist — '
              'once you do, a summary of what was extracted will show up here.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialDataSummary extends StatelessWidget {
  const _FinancialDataSummary({required this.state});

  final ProfileFinanceState state;

  @override
  Widget build(BuildContext context) {
    final latest = state.statements.first;
    final hasPeriod = latest.periodStart != null && latest.periodEnd != null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Extracted from your statements',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SummaryRow(
                label: 'Statements analyzed',
                value: '${state.statements.length}',
              ),
              const Divider(color: AppColors.border, height: AppSpacing.xl),
              _SummaryRow(
                label: 'Most recent upload',
                value: latest.uploadedAt.toMonthDayYear(),
              ),
              if (hasPeriod) ...[
                const Divider(color: AppColors.border, height: AppSpacing.xl),
                _SummaryRow(
                  label: 'Most recent period',
                  value: formatDateRange(
                    latest.periodStart!,
                    latest.periodEnd!,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'FinAssist uses this data only to answer your questions in chat. '
          'You can remove it at any time from "Delete financial data" on your Profile.',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}
