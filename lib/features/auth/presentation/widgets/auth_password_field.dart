import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'auth_text_field.dart';

/// A password field styled like [AuthTextField] (same [AuthInputCard]
/// shell) but with its own, independent visibility toggle — each instance
/// manages its own obscure state, so a login field and a confirm field
/// never share one.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.onChanged,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthInputCard(
      icon: Icons.lock_outline_rounded,
      label: widget.label,
      field: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        onChanged: widget.onChanged,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autofillHints: widget.autofillHints,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.authTextPrimary,
        ),
        cursorColor: AppColors.accentDeep,
        decoration: AuthInputCard.fieldDecoration(hintText: widget.hintText),
      ),
      trailing: Semantics(
        button: true,
        label: _obscure ? 'Show password' : 'Hide password',
        child: IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 19,
            color: AppColors.authTextMuted,
          ),
        ),
      ),
    );
  }
}
