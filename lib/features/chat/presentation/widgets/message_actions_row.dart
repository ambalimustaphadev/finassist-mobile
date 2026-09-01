import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Subtle "Copy" / "Regenerate" actions shown under the latest assistant
/// response only, so the conversation doesn't get cluttered with controls
/// on every bubble.
class MessageActionsRow extends StatefulWidget {
  const MessageActionsRow({
    super.key,
    required this.textToCopy,
    this.onRegenerate,
  });

  final String textToCopy;
  final VoidCallback? onRegenerate;

  @override
  State<MessageActionsRow> createState() => _MessageActionsRowState();
}

class _MessageActionsRowState extends State<MessageActionsRow> {
  bool _justCopied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    if (!mounted) return;
    setState(() => _justCopied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: _justCopied ? Icons.check_rounded : Icons.copy_rounded,
          label: _justCopied ? 'Copied' : 'Copy',
          semanticLabel: 'Copy response',
          onTap: _copy,
        ),
        if (widget.onRegenerate != null) ...[
          const SizedBox(width: AppSpacing.md),
          _ActionButton(
            icon: Icons.refresh_rounded,
            label: 'Regenerate',
            semanticLabel: 'Regenerate response',
            onTap: widget.onRegenerate!,
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
