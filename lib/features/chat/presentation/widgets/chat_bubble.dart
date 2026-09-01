import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/extensions/formatting_extensions.dart';
import '../../../../shared/widgets/ai_avatar.dart';
import '../../../../shared/widgets/document_viewer_screen.dart';
import '../../data/models/chat_message.dart';
import '../providers/chat_controller.dart';
import 'analysis_error_card.dart';
import 'file_attachment_card.dart';
import 'financial_breakdown_card.dart';
import 'follow_up_suggestions.dart';
import 'message_actions_row.dart';
import 'message_feedback_row.dart';
import 'recurring_payments_card.dart';
import 'upload_statement_button.dart';

/// Renders a single [ChatMessage] as a bubble, aligned left (AI) or right
/// (user), with any embedded rich content, follow-ups, actions and a
/// timestamp.
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
    final pendingAttachmentId = ref
        .watch(chatControllerProvider)
        .pendingAttachmentMessageId;

    final notifier = ref.read(chatControllerProvider.notifier);

    final isPendingAttachment =
        message.messageType == ChatMessageType.fileAttachment &&
        message.id == pendingAttachmentId;

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
                    // --------------------------------------------
                    // FILE ATTACHMENT
                    // --------------------------------------------
                    if (message.messageType == ChatMessageType.fileAttachment &&
                        message.fileAttachment != null)
                      FileAttachmentCard(
                        attachment: message.fileAttachment!,
                        onRemove: isPendingAttachment
                            ? () => notifier.removeAttachment(message.id)
                            : null,
                      )
                    // --------------------------------------------
                    // NORMAL MESSAGE (optionally with a file the user
                    // attached to this turn from the composer, shown as
                    // a compact tag above the text bubble rather than
                    // replacing it — unlike the standalone FILE
                    // ATTACHMENT case above, this message has real text
                    // alongside its file).
                    // --------------------------------------------
                    else if (message.messageType !=
                        ChatMessageType.analysisError) ...[
                      if (message.fileAttachment != null) ...[
                        FileAttachmentCard(
                          attachment: message.fileAttachment!,
                          onTap: message.fileAttachment!.fileUrl == null
                              ? null
                              : () => openDocumentViewer(
                                  context,
                                  fileUrl: message.fileAttachment!.fileUrl,
                                  filename: message.fileAttachment!.fileName,
                                  contentType:
                                      message.fileAttachment!.contentType,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: _isUser
                              ? AppColors.accentStrong
                              : AppColors.surfaceElevated,
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
                                  color: Colors.black87,
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
                    ]
                    // --------------------------------------------
                    // ANALYSIS ERROR
                    // --------------------------------------------
                    else
                      _AnalysisErrorBubble(message: message),

                    // --------------------------------------------
                    // FINANCIAL BREAKDOWN
                    // --------------------------------------------
                    if (message.messageType ==
                            ChatMessageType.categoryBreakdown &&
                        message.categoryBreakdown != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      FinancialBreakdownCard(
                        breakdown: message.categoryBreakdown!,
                      ),
                    ],

                    // --------------------------------------------
                    // RECURRING PAYMENTS
                    // --------------------------------------------
                    if (message.messageType ==
                            ChatMessageType.recurringPayments &&
                        message.recurringPayments != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      RecurringPaymentsCard(
                        payments: message.recurringPayments!,
                      ),
                    ],

                    // --------------------------------------------
                    // UPLOAD STATEMENT
                    // --------------------------------------------
                    if (message.messageType ==
                        ChatMessageType.uploadPrompt) ...[
                      const SizedBox(height: AppSpacing.sm),
                      UploadStatementButton(
                        onTap: notifier.pickAndUploadStatement,
                      ),
                    ],

                    // --------------------------------------------
                    // ANALYSIS ERROR ACTIONS
                    // --------------------------------------------
                    if (message.messageType == ChatMessageType.analysisError)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: AnalysisErrorCard(
                          onTryAgain: notifier.retryAnalysis,
                          onChooseAnother: notifier.pickAndUploadStatement,
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

/// Error bubble displayed when statement analysis fails.
class _AnalysisErrorBubble extends StatelessWidget {
  const _AnalysisErrorBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.negative,
          ),

          const SizedBox(width: AppSpacing.sm),

          Flexible(
            child: Text(
              message.text,
              style: AppTypography.chatMessage.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
