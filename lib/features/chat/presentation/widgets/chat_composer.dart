import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/statement_file_picker_service.dart';
import '../../../../shared/models/uploaded_file_attachment.dart';
import '../providers/chat_controller.dart';
import 'file_attachment_card.dart';

/// The bottom message composer: attachment affordance, an optional
/// attached-file preview, a text field and a circular send button.
///
/// Picking a file only updates this widget's own local state — it is
/// never uploaded, analyzed, or sent until the user actually taps Send,
/// at which point the text and the attachment go to
/// [ChatController.sendMessage] together (see its doc comment for the
/// upload-then-chat sequencing).
class ChatComposer extends ConsumerStatefulWidget {
  const ChatComposer({super.key, required this.onSend});

  final void Function(String text, PickedFile? attachment) onSend;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;
  PickedFile? _attachment;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAttach() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picked = await ref
          .read(statementFilePickerServiceProvider)
          .pickStatementFile();
      // A `null` result means the user cancelled the picker — nothing
      // happens, exactly as if they'd never tapped the button.
      if (picked != null && mounted) setState(() => _attachment = picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              "Couldn't open the file picker. Please try again.",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeAttachment() => setState(() => _attachment = null);

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty && _attachment == null) return;
    widget.onSend(text, _attachment);
    _controller.clear();
    setState(() => _attachment = null);
  }

  @override
  Widget build(BuildContext context) {
    // Disabled (not just visually, but functionally) while the
    // controller is mid-upload or waiting on the assistant's reply, so a
    // stray extra tap can never fire a second send.
    final isBusy = ref.watch(
      chatControllerProvider.select((s) => s.isAssistantTyping),
    );
    final hasContent = (_hasText || _attachment != null) && !isBusy;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          _attachment != null ? AppRadius.xl : AppRadius.pill,
        ),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attachment != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                0,
              ),
              child: FileAttachmentCard(
                attachment: UploadedFileAttachment(
                  fileName: _attachment!.name,
                  extension: _attachment!.extension,
                  sizeBytes: _attachment!.sizeBytes,
                ),
                onRemove: isBusy ? null : _removeAttachment,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Attach a financial document',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: isBusy ? null : _handleAttach,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: _isPicking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : const Icon(
                              Icons.attach_file_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isBusy,
                  style: AppTypography.chatMessage.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: 'Ask FinAssist...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SendButton(enabled: hasContent, onTap: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Send message',
      enabled: widget.enabled,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: widget.enabled ? AppColors.accent : AppColors.surfaceElevated,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: widget.enabled ? Colors.black87 : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
