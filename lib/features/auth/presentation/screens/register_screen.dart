import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/auth_controller.dart';
import '../utils/auth_validators.dart';
import '../widgets/account_created_sheet.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_privacy_note.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (!success || !mounted) return;

    await showAccountCreatedSheet(
      context,
      onContinue: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  void _handleGoToLogin() {
    // A stale error from a previous login attempt shouldn't greet the user
    // when they land back on Login.
    ref.read(authControllerProvider.notifier).clearErrors();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.authSurface,
      // Top safe area is handled by AuthHeader itself (so its dark
      // background can paint full-bleed behind the status bar); the
      // bottom (home indicator) inset is handled here.
      //
      // The header sits outside the scroll view on purpose: only the form
      // scrolls to stay reachable above the keyboard, while the heading
      // stays put instead of jumping around as the user types.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const AuthHeader(
              title: 'Create your account',
              subtitle:
                  'Join FinAssist and take control of your financial future.',
              illustrationIcon: Icons.account_balance_wallet_rounded,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        label: 'First name',
                        hintText: 'Enter first name',
                        icon: Icons.person_outline_rounded,
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        validator: (value) =>
                            AuthValidators.required(value, 'First name'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Last name',
                        hintText: 'Enter last name',
                        icon: Icons.person_outline_rounded,
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        validator: (value) =>
                            AuthValidators.required(value, 'Last name'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Email',
                        hintText: 'Enter email address',
                        icon: Icons.mail_outline_rounded,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: AuthValidators.email,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthTextField(
                        label: 'Username',
                        hintText: 'Enter username',
                        icon: Icons.alternate_email_rounded,
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        validator: (value) =>
                            AuthValidators.required(value, 'Username'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthPasswordField(
                        key: const ValueKey('register-password-field'),
                        label: 'Password',
                        hintText: 'Enter password',
                        controller: _passwordController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: AuthValidators.password,
                        onChanged: (_) => _formKey.currentState?.validate(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AuthPasswordField(
                        key: const ValueKey('register-confirm-password-field'),
                        label: 'Confirm password',
                        hintText: 'Confirm your password',
                        controller: _confirmPasswordController,
                        textInputAction: TextInputAction.done,
                        validator: (value) => AuthValidators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),
                      if (authState.registerError != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AuthErrorBanner(message: authState.registerError!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      const AuthPrivacyNote(),
                      const SizedBox(height: AppSpacing.lg),
                      AuthPrimaryButton(
                        label: 'Create account',
                        isLoading: authState.registerLoading,
                        onPressed: _handleCreateAccount,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTypography.body,
                            ),
                            GestureDetector(
                              onTap: _handleGoToLogin,
                              child: Text(
                                'Log in',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.accentDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
