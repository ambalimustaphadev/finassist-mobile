import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/confirm_action_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_controller.dart';

/// Manages the account's basic identity. Only first and last name are
/// editable here: `PATCH /api/profile` (see `ApiProfileRepository`) has no
/// way to change `username` or `email`, so both are shown read only
/// instead of pretending to accept an edit that would silently be
/// dropped. There's likewise no email-verification concept anywhere in
/// the backend contract, so the email field never claims a verified
/// state.
class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late String _savedFirstName;
  late String _savedLastName;
  String? _firstNameError;
  String? _lastNameError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).profile;
    _savedFirstName = profile?.firstName ?? '';
    _savedLastName = profile?.lastName ?? '';
    _firstNameController = TextEditingController(text: _savedFirstName)
      ..addListener(_onChanged);
    _lastNameController = TextEditingController(text: _savedLastName)
      ..addListener(_onChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _hasUnsavedChanges =>
      _firstNameController.text.trim() != _savedFirstName ||
      _lastNameController.text.trim() != _savedLastName;

  Future<void> _handlePop() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showConfirmActionDialog(
      context,
      title: 'Discard changes?',
      message: "You have unsaved changes. If you leave now, they'll be lost.",
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (ref.read(profileControllerProvider).isSaving) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    setState(() {
      _firstNameError = firstName.isEmpty ? 'Enter your first name.' : null;
      _lastNameError = lastName.isEmpty ? 'Enter your last name.' : null;
    });
    if (_firstNameError != null || _lastNameError != null) return;

    // Only the fields that actually changed go in the PATCH body.
    final changes = <String, dynamic>{
      if (firstName != _savedFirstName) 'first_name': firstName,
      if (lastName != _savedLastName) 'last_name': lastName,
    };
    if (changes.isEmpty) return;

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(changes);
    if (!mounted) return;

    if (success) {
      _savedFirstName = firstName;
      _savedLastName = lastName;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              'Your details have been updated.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            ref.read(profileControllerProvider).saveError ??
                "Couldn't update your details. Try again.",
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    // Same fallback the header uses: if `/api/profile` hasn't loaded,
    // username/email still come from the already-authenticated session
    // rather than showing blank.
    final authUser = ref.watch(authControllerProvider.select((s) => s.user));
    final username = profile?.username ?? authUser?.username ?? '';
    final email = profile?.email ?? authUser?.email ?? '';

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            onPressed: _handlePop,
          ),
          title: Text(
            'Personal Information',
            style: AppTypography.screenTitle,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Manage the details associated with your account.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _SectionHeader(
                title: 'Basic Information',
                subtitle: 'Your name and account identity.',
              ),
              const SizedBox(height: AppSpacing.md),
              _EditableField(
                label: 'First name',
                icon: Icons.person_outline_rounded,
                controller: _firstNameController,
                errorText: _firstNameError,
              ),
              _EditableField(
                label: 'Last name',
                icon: Icons.person_outline_rounded,
                controller: _lastNameController,
                errorText: _lastNameError,
              ),
              _ReadOnlyField(
                label: 'Username',
                icon: Icons.alternate_email_rounded,
                value: '@$username',
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  top: AppSpacing.xs,
                ),
                child: Text(
                  'This is how you appear on FinAssist and can be seen by others.',
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _SectionHeader(
                title: 'Account Contact',
                subtitle:
                    "We'll use this to keep you informed about important updates.",
                dense: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _ReadOnlyField(
                label: 'Email address',
                icon: Icons.mail_outline_rounded,
                value: email,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: _hasUnsavedChanges
                      ? AppColors.accentDeep
                      : AppColors.accentDeep.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    onTap: profileState.isSaving || !_hasUnsavedChanges
                        ? null
                        : _save,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: profileState.isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save changes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section title, prominent for "Basic Information" and visually
/// lighter (smaller, muted) for "Account Contact" via [dense], so contact
/// info reads as secondary to identity.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  final String title;
  final String subtitle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: dense
              ? AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                )
              : AppTypography.sectionHeading,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// A rounded, icon-led input card for a field the user can actually edit.
class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.icon,
    required this.controller,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: errorText != null
                ? AppColors.negative
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      errorText: errorText,
                      errorStyle: const TextStyle(
                        color: AppColors.negative,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A visually distinct (muted fill, lock glyph) card for a field the
/// backend doesn't support editing — never a [TextField], so there's no
/// cursor or edit affordance to suggest otherwise.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
