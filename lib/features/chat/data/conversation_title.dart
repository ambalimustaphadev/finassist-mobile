/// Generic, client-side fallback for a conversation's title: the first
/// user message, cleaned up and capped to a short length. Used until the
/// backend provides an official title (see `Conversation.title`).
///
/// Deliberately simple (no AI call) — trims whitespace, drops a trailing
/// "?"/"."/"!" run, caps the length, and capitalizes the first letter, so
/// "How much did I spend on food last month?" becomes "How much did I
/// spend on food last month".
String suggestConversationTitle(String userMessage) {
  final trimmed = userMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.isEmpty) return 'New conversation';

  final withoutTrailingPunctuation = trimmed.replaceAll(RegExp(r'[.?!]+$'), '');
  if (withoutTrailingPunctuation.isEmpty) return 'New conversation';

  const maxLength = 42;
  final capped = withoutTrailingPunctuation.length > maxLength
      ? '${withoutTrailingPunctuation.substring(0, maxLength).trimRight()}…'
      : withoutTrailingPunctuation;

  return capped[0].toUpperCase() + capped.substring(1);
}
