import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// A compact rounded input "card" — leading icon, a small label sitting
/// above the value, and the field itself styled as plain text rather than
/// a boxed `TextFormField` — matching the reference's input treatment.
/// Used directly by [AuthTextField]; [AuthPasswordField] builds the same
/// visual shell with its own obscure-text state and trailing toggle.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  /// Defaults to [TextCapitalization.sentences] — the right default for
  /// most fields. Callers whose field is a machine-readable value (email,
  /// username) or should capitalize every word (a person's name) pass
  /// their own.
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return AuthInputCard(
      icon: icon,
      label: label,
      field: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.authTextPrimary,
        ),
        cursorColor: AppColors.accentDeep,
        decoration: AuthInputCard.fieldDecoration(hintText: hintText),
      ),
    );
  }
}

/// Shared shell for [AuthTextField]/[AuthPasswordField]: a rounded,
/// softly-bordered card containing a leading icon and, stacked to its
/// right, the small field [label] above the actual [field] widget —
/// deliberately not one `TextFormField` styled with `prefixIcon`/`label`,
/// since the reference's label sits permanently above the value rather
/// than floating/collapsing into it.
class AuthInputCard extends StatelessWidget {
  const AuthInputCard({
    super.key,
    required this.icon,
    required this.label,
    required this.field,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget field;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.authInputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.authInputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.authTextMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.authTextMuted,
                  ),
                ),
                field,
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  /// The zero-chrome `InputDecoration` every field inside the card shares:
  /// no visible border/fill of its own (the card already draws that), so
  /// the field reads as plain value text under the label rather than a
  /// second nested box.
  static InputDecoration fieldDecoration({required String hintText}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.authTextMuted,
      ),
      errorStyle: AppTypography.caption.copyWith(
        color: AppColors.negative,
        height: 0.7,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      isCollapsed: false,
    );
  }
}
