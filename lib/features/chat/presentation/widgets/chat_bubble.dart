import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/models/uploaded_file_attachment.dart';
import '../../../../shared/widgets/ai_avatar.dart';
import '../../../../shared/widgets/document_viewer_screen.dart';
import '../../../profile/presentation/providers/profile_finance_controller.dart';
import '../../data/models/chat_message.dart';
import '../providers/chat_controller.dart';
import 'file_attachment_card.dart';
import 'follow_up_suggestions.dart';
import 'message_actions_row.dart';
import 'message_feedback_row.dart';

/// Renders a single [ChatMessage] as a bubble, aligned left (AI) or right
/// (user), with its optional file attachment, follow-ups, actions and a
/// timestamp — every AI response is a plain chat message, never a
/// fabricated financial dashboard card.
class ChatBubble extends ConsumerWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onFollowUpSelected,
    this.showAssistantActions = false,
  });

  final ChatMessage message;
  final ValueChanged<String>? onFollowUpSelected;

  /// Whether to show the subtle copy/regenerate and helpful/not-helpful
  /// controls — reserved for the latest substantive assistant reply so the
  /// conversation doesn't get cluttered with controls on every bubble.
  final bool showAssistantActions;

  bool get _isUser => message.role == ChatMessageRole.user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(chatControllerProvider.notifier);

    return Column(
      crossAxisAlignment: _isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: _isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isUser) ...[
              const AIAvatar(size: 30),
              const SizedBox(width: AppSpacing.sm),
            ],

            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                child: Column(
                  crossAxisAlignment: _isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // A file the user attached to this turn, shown as a
                    // compact tag above the text bubble rather than
                    // replacing it — the document itself belongs to this
                    // conversation, not a separate Documents section.
                    if (message.fileAttachment != null) ...[
                      FileAttachmentCard(
                        attachment: message.fileAttachment!,
                        onTap: message.fileAttachment!.fileId == null
                            ? null
                            : () => _openAttachment(
                                context,
                                ref,
                                message.fileAttachment!,
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    // A file-only message (no typed text — the user
                    // attached a document and sent it as-is) has nothing
                    // to show here: the attachment card above already
                    // represents the whole message, so no empty bubble
                    // is rendered beneath it.
                    if (message.text.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _isUser
                              ? AppColors.surfaceHighlight
                              : AppColors.surface,
                          border: _isUser
                              ? null
                              : Border.all(color: AppColors.borderSubtle),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppRadius.lg),
                            topRight: const Radius.circular(AppRadius.lg),
                            bottomLeft: Radius.circular(
                              _isUser ? AppRadius.lg : 4,
                            ),
                            bottomRight: Radius.circular(
                              _isUser ? 4 : AppRadius.lg,
                            ),
                          ),
                          boxShadow: _isUser
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),

                        // User messages stay as normal Text.
                        //
                        // AI messages use Markdown so things like:
                        //
                        // **important**
                        //
                        // - Food
                        // - Transport
                        //
                        // are rendered properly.
                        child: _isUser
                            ? Text(
                                message.text,
                                style: AppTypography.chatMessage.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : MarkdownBody(
                                data: message.text,
                                shrinkWrap: true,
                                selectable: false,
                                styleSheet: MarkdownStyleSheet(
                                  p: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                  ),

                                  strong: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.45,
                                  ),

                                  em: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    fontStyle: FontStyle.italic,
                                    height: 1.45,
                                  ),

                                  h1: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),

                                  h2: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),

                                  h3: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),

                                  listBullet: AppTypography.chatMessage
                                      .copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.45,
                                      ),

                                  blockquote: AppTypography.chatMessage
                                      .copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.45,
                                      ),

                                  // flutter_markdown merges this with its
                                  // own fallback stylesheet (see
                                  // MarkdownWidget's `fallbackStyleSheet
                                  // .merge(styleSheet)`), whose default
                                  // `code` style carries a chip-like
                                  // `backgroundColor` and a monospace font.
                                  // TextStyle.merge only overrides fields
                                  // we set here, so both must be
                                  // explicitly overridden — otherwise the
                                  // fallback's tinted background/monospace
                                  // font leaks through even though this
                                  // style sheet never asked for it.
                                  // FinAssist is a financial assistant, not
                                  // a code editor: inline code (and even a
                                  // whole sentence wrapped in backticks)
                                  // should read as plain assistant text.
                                  code: AppTypography.chatMessage.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                    backgroundColor: Colors.transparent,
                                  ),

                                  codeblockDecoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),

                                  horizontalRuleDecoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.border),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                    // --------------------------------------------
                    // FINANCIAL DATA INDICATOR
                    // --------------------------------------------
                    if (!_isUser && message.usedFinancialData == true) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Based on your financial data',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ],

                    // --------------------------------------------
                    // FOLLOW-UP SUGGESTIONS
                    // --------------------------------------------
                    if (message.followUpSuggestions.isNotEmpty &&
                        onFollowUpSelected != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FollowUpSuggestions(
                        suggestions: message.followUpSuggestions,
                        onSelect: onFollowUpSelected!,
                      ),
                    ],

                    // --------------------------------------------
                    // MESSAGE ACTIONS
                    // --------------------------------------------
                    if (showAssistantActions) ...[
                      const SizedBox(height: AppSpacing.sm),

                      MessageActionsRow(
                        textToCopy: message.text,
                        onRegenerate: () =>
                            notifier.regenerateResponse(message.id),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      MessageFeedbackRow(message: message),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),

        // --------------------------------------------
        // TIMESTAMP / SEND STATUS
        // --------------------------------------------
        Padding(
          padding: EdgeInsets.only(
            top: 4,
            left: _isUser ? 0 : 38,
            right: _isUser ? 4 : 0,
          ),
          child: message.sendFailed
              ? _FailedToSendRow(onRetry: () => notifier.retrySend(message.id))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timestamp.toTimeOfDay(),
                      style: AppTypography.caption,
                    ),

                    if (_isUser) ...[
                      const SizedBox(width: 4),

                      const Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Opens a tapped [FileAttachmentCard]'s document: the document is private
/// in R2, so this always asks the backend for a fresh, short-lived signed
/// URL first (never reusing/storing one) and only opens the shared viewer
/// once that succeeds. Shows a blocking spinner for the (usually brief)
/// round trip and a friendly error if it fails, rather than a raw
/// exception message.
Future<void> _openAttachment(
  BuildContext context,
  WidgetRef ref,
  UploadedFileAttachment attachment,
) async {
  final fileId = attachment.fileId;
  if (fileId == null) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String signedUrl;
  try {
    signedUrl = await ref.read(documentRepositoryProvider).getViewUrl(fileId);
  } catch (_) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't open this document. Please try again."),
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await openDocumentViewer(
    context,
    fileUrl: signedUrl,
    filename: attachment.fileName,
    contentType: attachment.contentType,
  );
}

/// Shown beneath a user message that failed to send, in place of the
/// normal timestamp — an honest "this didn't go through" state with a way
/// to fix it, instead of silently pretending it sent.
class _FailedToSendRow extends StatelessWidget {
  const _FailedToSendRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 13,
            color: AppColors.negative,
          ),
          const SizedBox(width: 4),
          Text(
            'Failed to send · Retry',
            style: AppTypography.caption.copyWith(color: AppColors.negative),
          ),
        ],
      ),
    );
  }
}
