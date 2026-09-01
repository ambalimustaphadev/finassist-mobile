import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/uploaded_statement.dart';
import '../providers/profile_finance_controller.dart';

/// Lists the bank statements this device has actually uploaded and had
/// analyzed, and lets the user upload another one — reusing the same
/// file-picker and analysis pipeline the chat feature already uses.
class StatementsScreen extends ConsumerWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileFinanceControllerProvider);
    final notifier = ref.read(profileFinanceControllerProvider.notifier);

    ref.listen(profileFinanceControllerProvider, (previous, next) {
      if (next.uploadStatus == previous?.uploadStatus) return;
      switch (next.uploadStatus) {
        case StatementUploadStatus.success:
          _showSnack(
            context,
            next.uploadMessage ?? 'Statement uploaded.',
            isError: false,
          );
          notifier.dismissUploadStatus();
        case StatementUploadStatus.error:
        case StatementUploadStatus.unavailable:
          _showSnack(
            context,
            next.uploadMessage ?? "Couldn't upload that statement.",
            isError: true,
          );
          notifier.dismissUploadStatus();
        case StatementUploadStatus.uploading:
        case StatementUploadStatus.idle:
          break;
      }
    });

    final isUploading = state.uploadStatus == StatementUploadStatus.uploading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Uploaded statements', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.isLoadingStatements
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2.2,
                      ),
                    )
                  : state.statements.isEmpty
                  ? const _EmptyStatements()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: state.statements.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _StatementTile(statement: state.statements[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    onTap: isUploading ? null : notifier.uploadStatement,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                          : const Text(
                              'Upload a statement',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: isError ? AppColors.negative : AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _EmptyStatements extends StatelessWidget {
  const _EmptyStatements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(
              icon: Icons.description_outlined,
              color: AppColors.textMuted,
              size: 56,
              iconSize: 26,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No statements yet', style: AppTypography.sectionHeading),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Upload a bank statement to start building your financial picture.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementTile extends StatelessWidget {
  const _StatementTile({required this.statement});

  final UploadedStatement statement;

  Future<void> _open(BuildContext context) async {
    final url = statement.fileUrl;
    if (url == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              "This statement doesn't have a document to open.",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
      return;
    }

    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              "Couldn't open this document.",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPeriod =
        statement.periodStart != null && statement.periodEnd != null;
    return AppCard(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _open(context),
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.description_rounded,
            color: AppColors.accentStrong,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statement.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  hasPeriod
                      ? formatDateRange(
                          statement.periodStart!,
                          statement.periodEnd!,
                        )
                      : 'Uploaded ${statement.uploadedAt.toMonthDayYear()}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
