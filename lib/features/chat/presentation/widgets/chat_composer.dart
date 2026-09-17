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
  const ChatComposer({
    super.key,
    required this.onSend,
    this.hasMessages = false,
  });

  final void Function(String text, PickedFile? attachment) onSend;

  /// Whether the active conversation already has messages — swaps the
  /// placeholder from an opening invitation to a follow-up prompt.
  final bool hasMessages;

  @override
  ConsumerState<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends ConsumerState<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _focused = false;
  PickedFile? _attachment;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _focused) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.surfaceElevated,
            content: Text(
              "Couldn't open the file picker. Please try again.",
              style: TextStyle(color: context.colors.textPrimary),
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
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(
          _attachment != null ? AppRadius.xl : AppRadius.pill,
        ),
        border: Border.all(
          color: _focused
              ? context.colors.accent.withValues(alpha: 0.55)
              : context.colors.borderSubtle,
          width: _focused ? 1.5 : 1,
        ),
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
                      padding: const EdgeInsets.all(8),
                      child: _isPicking
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.textSecondary,
                              ),
                            )
                          : Icon(
                              Icons.attach_file_rounded,
                              color: context.colors.textSecondary,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !isBusy,
                  style: AppTypography.chatMessage(context).copyWith(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    height: 1.3,
                  ),
                  cursorColor: context.colors.accent,
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    // Explicitly opts this field out of the app-wide
                    // InputDecorationTheme's `filled`/OutlineInputBorder
                    // defaults (see AppTheme) — otherwise the decorator
                    // paints its own smaller rounded-rect fill *inside*
                    // this pill-shaped outer container, which is exactly
                    // the "box inside a box" look this composer must not
                    // have. This field is visually just text on the
                    // composer's own surface.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: widget.hasMessages
                        ? 'Ask a follow-up...'
                        : 'Ask FinAssist anything...',
                    hintStyle: AppTypography.body(context).copyWith(
                      color: context.colors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
          color: widget.enabled
              ? context.colors.accent
              : context.colors.surfaceElevated,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: widget.enabled
                    ? context.colors.textOnAccent
                    : context.colors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
