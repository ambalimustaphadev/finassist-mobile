import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/models/subscription.dart';
import '../../domain/subscription_filter.dart';
import '../providers/subscription_controller.dart';
import '../widgets/subscription_empty_state.dart';
import '../widgets/subscription_filter_sheet.dart';
import '../widgets/subscription_list_tile.dart';
import 'add_subscription_flow_screen.dart';
import 'subscription_detail_screen.dart';

/// The full subscription list — search, status tabs and the detailed
/// filter sheet, all applied client-side over the already-loaded list.
class AllSubscriptionsScreen extends ConsumerStatefulWidget {
  const AllSubscriptionsScreen({super.key});

  @override
  ConsumerState<AllSubscriptionsScreen> createState() =>
      _AllSubscriptionsScreenState();
}

class _AllSubscriptionsScreenState extends ConsumerState<AllSubscriptionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  SubscriptionFilters _filters = SubscriptionFilters.empty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showSubscriptionFilterSheet(
      context,
      initial: _filters,
    );
    if (result != null) setState(() => _filters = result);
  }

  void _setStatus(SubscriptionStatus? status) {
    setState(() {
      _filters = status == null
          ? _filters.copyWith(clearStatus: true)
          : _filters.copyWith(status: status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsControllerProvider);
    final all = state.subscriptions;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'All subscriptions',
          style: AppTypography.screenTitle(context),
        ),
      ),
      body: SafeArea(
        child: state.status == SubscriptionsLoadStatus.loading
            ? const LoadingStateView(height: 400)
            : state.status == SubscriptionsLoadStatus.error
            ? ErrorStateView(
                message: state.loadError ?? 'Something went wrong. Please try again.',
                onRetry: () =>
                    ref.read(subscriptionsControllerProvider.notifier).refresh(),
              )
            : all.isEmpty
            ? SubscriptionEmptyState(
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddSubscriptionFlowScreen(),
                  ),
                ),
              )
            : _ListContent(
                all: all,
                query: _query,
                filters: _filters,
                searchController: _searchController,
                onQueryChanged: (value) => setState(() => _query = value),
                onOpenFilters: _openFilters,
                onStatusSelected: _setStatus,
              ),
      ),
    );
  }
}

class _ListContent extends StatelessWidget {
  const _ListContent({
    required this.all,
    required this.query,
    required this.filters,
    required this.searchController,
    required this.onQueryChanged,
    required this.onOpenFilters,
    required this.onStatusSelected,
  });

  final List<Subscription> all;
  final String query;
  final SubscriptionFilters filters;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilters;
  final ValueChanged<SubscriptionStatus?> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final filtered = filterSubscriptions(
      all,
      query: query,
      status: filters.status,
      category: filters.category,
      frequency: filters.frequency,
      paymentMethod: filters.paymentMethod,
    );

    int countFor(SubscriptionStatus? status) => filterSubscriptions(
      all,
      status: status,
    ).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: onQueryChanged,
                  style: AppTypography.body(
                    context,
                  ).copyWith(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search subscriptions...',
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
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: filters.isEmpty
                    ? context.colors.surface
                    : context.colors.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: onOpenFilters,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    child: Icon(
                      Icons.tune_rounded,
                      color: filters.isEmpty
                          ? context.colors.textPrimary
                          : context.colors.textOnAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusTab(
                  label: 'All (${countFor(null)})',
                  selected: filters.status == null,
                  onTap: () => onStatusSelected(null),
                ),
                for (final status in SubscriptionStatus.values) ...[
                  const SizedBox(width: AppSpacing.md),
                  _StatusTab(
                    label: '${status.label} (${countFor(status)})',
                    selected: filters.status == status,
                    onTap: () => onStatusSelected(status),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      'No subscriptions match your search or filters.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(context).copyWith(
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final subscription = filtered[index];
                    return SubscriptionListTile(
                      subscription: subscription,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubscriptionDetailScreen(
                            subscriptionId: subscription.id,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

}

class _StatusTab extends StatelessWidget {
  const _StatusTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          label,
          style:
              (selected
                      ? AppTypography.bodyMedium(context)
                      : AppTypography.body(context))
                  .copyWith(
                    color: selected
                        ? context.colors.accentStrong
                        : context.colors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
        ),
      ),
    );
  }
}
