import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/finassist_logo.dart';
import '../providers/auth_controller.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_checkbox.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            'Password reset is coming soon',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  void _handleGoToRegister() {
    // A stale error from a previous register attempt shouldn't greet the
    // user when they land back on Register.
    ref.read(authControllerProvider.notifier).clearErrors();
    Navigator.of(context).pushNamed(AppRoutes.register);
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
                title: 'Welcome back',
                subtitle:
                    'Sign in to continue your financial journey with FinAssist.',
              ),
              const SizedBox(height: AppSpacing.xxl),
              AuthTextField(
                label: 'Email address',
                hintText: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthPasswordField(
                key: const ValueKey('login-password-field'),
                label: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) => AuthValidators.password(value),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Remember me',
                      child: InkWell(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AuthCheckbox(value: _rememberMe),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  'Remember me',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.authTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (authState.loginError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AuthErrorBanner(message: authState.loginError!),
              ],
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(
                label: 'Login',
                isLoading: authState.loginLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: AppSpacing.xl),
              const AuthDivider(label: 'Or continue with'),
              const SizedBox(height: AppSpacing.xl),
              const SocialAuthButtons(),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: AppTypography.body),
                    GestureDetector(
                      onTap: _handleGoToRegister,
                      child: Text(
                        'Register',
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
