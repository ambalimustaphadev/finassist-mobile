import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/finassist_logo.dart';
import '../../../profile/presentation/widgets/unavailable_feature_screen.dart';
import '../providers/auth_controller.dart';
import '../utils/auth_validators.dart';
import '../widgets/account_created_screen.dart';
import '../widgets/auth_checkbox.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_buttons.dart';

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
  bool _agreedToTerms = false;
  bool _showTermsError = false;

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
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTermsError = !_agreedToTerms);
    if (!formValid || !_agreedToTerms) return;

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

    await showAccountCreatedScreen(
      context,
      onContinue: () {
        // Register is pushed on top of Login for a returning user
        // (Login -> "Register"), but is `AuthGate`'s unauthenticated root
        // itself for a fresh/reset device — nothing to pop back to there.
        // Either way, `AuthGate` has already reactively swapped to the
        // authenticated branch underneath by now (the `register()` call
        // above signs the new account in), so popping when possible is
        // enough to reveal it; there's nothing to do when it isn't.
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _handleGoToLogin() {
    // A stale error from a previous login attempt shouldn't greet the user
    // when they land back on Login.
    ref.read(authControllerProvider.notifier).clearErrors();
    final navigator = Navigator.of(context);
    // Register is reached by being pushed on top of Login for a returning
    // user — pop back to it. For a fresh/reset device, Register is
    // `AuthGate`'s unauthenticated root itself (nothing to pop to), so push
    // Login instead; `AuthScaffold`'s back arrow (driven by `canPop`) then
    // lets them return to Register the same way Register's own back arrow
    // already works from Login.
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamed(AppRoutes.login);
    }
  }

  void _openLegal(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnavailableFeatureScreen(
          title: title,
          icon: Icons.description_outlined,
          message: "$title isn't available inside the app yet.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthScaffold(
      builder: (context) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: FinAssistLogo(height: 56)),
              const SizedBox(height: AppSpacing.xxl),
              const AuthHeader(
                title: 'Create your \n Account',
                subtitle:
                    'Join FinAssist and take the first step '
                    'towards a smarter financial future.',
              ),
              const SizedBox(height: AppSpacing.xxl),
              AuthTextField(
                label: 'First name',
                hintText: 'Mustapha',
                icon: Icons.person_outline_rounded,
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
                validator: (value) =>
                    AuthValidators.required(value, 'First name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Last name',
                hintText: 'Adewole',
                icon: Icons.person_outline_rounded,
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.familyName],
                validator: (value) =>
                    AuthValidators.required(value, 'Last name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Email address',
                hintText: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
                textCapitalization: TextCapitalization.none,
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
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthPasswordField(
                key: const ValueKey('register-password-field'),
                label: 'Password',
                hintText: 'Create a strong password',
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
              const SizedBox(height: AppSpacing.lg),
              _TermsCheckbox(
                value: _agreedToTerms,
                showError: _showTermsError,
                onChanged: (value) => setState(() {
                  _agreedToTerms = value;
                  if (value) _showTermsError = false;
                }),
                onTapTerms: () => _openLegal('Terms of Service'),
                onTapPrivacy: () => _openLegal('Privacy Policy'),
              ),
              if (authState.registerError != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AuthErrorBanner(message: authState.registerError!),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(
                label: 'Create account',
                isLoading: authState.registerLoading,
                onPressed: _handleCreateAccount,
              ),
              const SizedBox(height: AppSpacing.xl),
              const AuthDivider(label: 'Or sign up with'),
              const SizedBox(height: AppSpacing.xl),
              const SocialAuthButtons(),
              const SizedBox(height: AppSpacing.xxl),
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
        );
      },
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTypography.caption.copyWith(
      color: AppColors.accentDeep,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accentDeep,
    );
    final textStyle = AppTypography.caption.copyWith(
      color: AppColors.authTextPrimary,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: 'I agree to the Terms of Service and Privacy Policy',
              child: InkWell(
                onTap: () => onChanged(!value),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AuthCheckbox(value: value),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RichText(
                  text: TextSpan(
                    style: textStyle,
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()..onTap = onTapTerms,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: linkStyle,
                        recognizer: TapGestureRecognizer()
                          ..onTap = onTapPrivacy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 28),
            child: Text(
              'Please agree to the Terms of Service and Privacy Policy.',
              style: AppTypography.caption.copyWith(color: AppColors.negative),
            ),
          ),
      ],
    );
  }
}
