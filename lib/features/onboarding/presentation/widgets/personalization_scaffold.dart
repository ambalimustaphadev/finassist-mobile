import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import 'personalization_header.dart';

/// The shared chrome for personalization pages 1–5: [PersonalizationHeader]
/// at a fixed top position, then an eyebrow/headline/description/body
/// column, then a full-width bottom CTA pill — only the body content and
/// copy change between screens, matching the reference. Page 6 (the
/// completion page) is visually distinct enough (robot art, summary card)
/// that it builds its own layout directly on top of the same
/// [PersonalizationHeader] instead of reusing this scaffold's body/CTA
/// slots.
class PersonalizationScaffold extends StatelessWidget {
  const PersonalizationScaffold({
    super.key,
    required this.step,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    this.onBack,
    this.onSkip,
    required this.onContinue,
    this.continueLabel = 'Continue',
    this.continueEnabled = true,
    this.isSaving = false,
  });

  /// 1-based, e.g. `1` for "1 of 6".
  final int step;

  /// Small uppercase label above the headline — absent on Page 1 (the
  /// introduction has no question to label).
  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback onContinue;
  final String continueLabel;
  final bool continueEnabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            PersonalizationHeader(step: step, onBack: onBack, onSkip: onSkip),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null) ...[
                            Text(
                              eyebrow!,
                              style: AppTypography.caption(context).copyWith(
                                color: context.colors.accentStrong,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Text(
                            title,
                            style: AppTypography.greeting(context).copyWith(
                              fontSize: 26,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            subtitle,
                            style: AppTypography.body(context).copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          body,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: PersonalizationContinueButton(
                step: step,
                label: continueLabel,
                enabled: continueEnabled,
                isSaving: isSaving,
                onTap: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full-width emerald "Continue" pill shared by every personalization
/// page's bottom CTA (including the bespoke completion page, which uses
/// this directly rather than the whole [PersonalizationScaffold]).
class PersonalizationContinueButton extends StatelessWidget {
  const PersonalizationContinueButton({
    super.key,
    required this.step,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isSaving = false,
  });

  final int step;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? context.colors.accent
            : context.colors.accent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          key: Key('personalization-continue-$step'),
          onTap: (enabled && !isSaving) ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: context.colors.textOnAccent,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: AppTypography.buttonLabel(context).copyWith(
                            color: context.colors.textOnAccent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: context.colors.textOnAccent,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
