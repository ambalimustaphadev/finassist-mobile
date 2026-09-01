import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/auth_controller.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    // On success, AuthGate reactively swaps to the dashboard — no
    // navigation call needed here. On failure, authState.loginError
    // renders inline below.
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
              title: 'Welcome back',
              subtitle:
                  'Sign in to continue your financial journey with FinAssist.',
              illustrationIcon: Icons.show_chart_rounded,
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
                      AuthPasswordField(
                        key: const ValueKey('login-password-field'),
                        label: 'Password',
                        hintText: 'Enter password',
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) => AuthValidators.password(value),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentDeep,
                            ),
                          ),
                        ),
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
                      const SizedBox(height: AppSpacing.lg),
                      const AuthDivider(),
                      const SizedBox(height: AppSpacing.lg),
                      const GoogleSignInButton(),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTypography.body,
                            ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
