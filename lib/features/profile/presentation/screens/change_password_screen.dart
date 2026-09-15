import 'package:flutter/material.dart';

import '../widgets/unavailable_feature_screen.dart';

/// `authroute.py` only exposes `/api/register`, `/api/login`, `/api/refresh`
/// and `/api/me` — there is no endpoint to change a password from the app
/// yet. Rather than building a form that can never actually submit
/// anywhere, this stays an honest "not available yet" screen (reached from
/// both Account and Security) until that endpoint exists.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnavailableFeatureScreen(
      title: 'Change password',
      icon: Icons.lock_outline_rounded,
      message:
          "Changing your password from the app isn't available yet. "
          'Contact support if you need help accessing your account.',
    );
  }
}
