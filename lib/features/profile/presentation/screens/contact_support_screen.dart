import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_controller.dart';

const _supportEmail = 'support@finassist.com';

const _categories = [
  'Account & login',
  'Technical issue',
  'Documents',
  'Privacy & data',
  'Notifications',
  'Other',
];

/// There's no backend support/contact endpoint today, so this doesn't
/// pretend to submit a request to one. Instead it opens the device's own
/// email app with the category and description already filled in — a real
/// action `url_launcher` can actually perform, rather than a fake
/// "message sent" confirmation for a request that went nowhere.
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _descriptionController = TextEditingController();
  String _category = _categories.first;
  String? _descriptionError;
  bool _isSending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending) return;
    final description = _descriptionController.text.trim();
    setState(() {
      _descriptionError = description.isEmpty
          ? 'Tell us a bit more about what happened.'
          : null;
    });
    if (_descriptionError != null) return;

    setState(() => _isSending = true);

    final profile = ref.read(profileControllerProvider).profile;
    final authUser = ref.read(authControllerProvider).user;
    final email = profile?.email ?? authUser?.email;

    final bodyLines = [
      description,
      '',
      '---',
      'Category: $_category',
      if (email != null) 'Account: $email',
      'App version: 1.0.0 (1)',
      'Platform: ${Platform.operatingSystem}',
      'OS version: ${Platform.operatingSystemVersion}',
    ];

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query:
          'subject=${Uri.encodeComponent('FinAssist support: $_category')}'
          '&body=${Uri.encodeComponent(bodyLines.join('\n'))}',
    );

    final opened = await launchUrl(uri);
    if (!mounted) return;
    setState(() => _isSending = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            opened
                ? 'Opening your email app so you can send this to us.'
                : "Couldn't open your email app. Please try again.",
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Contact support', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Tell us what happened and we\'ll get back to you.',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Category', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceElevated,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  items: [
                    for (final category in _categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Description', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'What happened?',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                ),
                errorText: _descriptionError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  onTap: _isSending ? null : _send,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: _isSending
                        ? const Center(
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        : const Text(
                            'Send',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
