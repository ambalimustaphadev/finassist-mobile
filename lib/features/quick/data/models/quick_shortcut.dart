import 'package:flutter/material.dart';

/// A shortcut into a fresh AI conversation — either sends [prompt]
/// immediately, or (for [triggersUpload]) opens the statement picker
/// instead. Deliberately separate from `chat`'s `QuickAction` (which drives
/// the in-conversation suggestion row above the composer) — this one
/// always starts a *new* conversation from outside Chat entirely.
class QuickShortcut {
  const QuickShortcut({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.prompt = '',
    this.triggersUpload = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String prompt;
  final bool triggersUpload;
}
