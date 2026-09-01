import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/models/uploaded_file_attachment.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

/// Shows a file the user attached to the conversation (e.g. a bank
/// statement) as a compact card, matching the app's statement-card styling.
class FileAttachmentCard extends StatelessWidget {
  const FileAttachmentCard({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  final UploadedFileAttachment attachment;

  /// When set, shows a "×" affordance — only meaningful before analysis
  /// has started for this file.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final visual = _fileVisualFor(attachment.extensionLabel);

    return AppCard(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IconBadge(
            icon: visual.icon,
            color: visual.color,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.fileName,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (attachment.extensionLabel.isNotEmpty)
                      attachment.extensionLabel,
                    if (attachment.sizeLabel.isNotEmpty) attachment.sizeLabel,
                  ].join(' · '),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            Semantics(
              button: true,
              label: 'Remove attached file',
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FileVisual {
  const _FileVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

_FileVisual _fileVisualFor(String extensionLabel) {
  switch (extensionLabel.toUpperCase()) {
    case 'PDF':
      return const _FileVisual(
        Icons.picture_as_pdf_rounded,
        AppColors.negative,
      );
    case 'CSV':
    case 'XLS':
    case 'XLSX':
      return const _FileVisual(
        Icons.table_chart_rounded,
        AppColors.accentStrong,
      );
    default:
      return const _FileVisual(
        Icons.description_rounded,
        AppColors.categoryOthers,
      );
  }
}
