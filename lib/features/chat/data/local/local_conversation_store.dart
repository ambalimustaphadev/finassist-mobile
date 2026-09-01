import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Client-side persistence for conversations and their messages, keyed per
/// user so switching accounts on the same device never bleeds one user's
/// history into another's.
///
/// This is an offline cache in front of the backend, not a substitute for
/// it: the backend (`/api/conversations`) is the source of truth whenever
/// it's reachable. `ChatController` writes through to this store after
/// every successful backend read/write, and falls back to reading from it
/// only when the backend call itself fails (no session, network error).
class LocalConversationStore {
  LocalConversationStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String userId) => 'chat_conversations_v1_$userId';

  Future<List<_StoredConversation>> _readAll(String userId) async {
    final raw = await _storage.read(key: _key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => _StoredConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt/unreadable local cache — treat as empty rather than crash.
      return [];
    }
  }

  Future<void> _writeAll(String userId, List<_StoredConversation> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.write(key: _key(userId), value: raw);
  }

  Future<List<Conversation>> loadConversations(String userId) async {
    final stored = await _readAll(userId);
    return stored.map((e) => e.conversation).toList();
  }

  Future<List<ChatMessage>> loadMessages(
    String userId,
    String conversationId,
  ) async {
    final stored = await _readAll(userId);
    final match = stored.where((e) => e.conversation.id == conversationId);
    return match.isEmpty ? const [] : match.first.messages;
  }

  /// Upserts [conversation] and its [messages] as one unit.
  Future<void> saveConversation(
    String userId,
    Conversation conversation,
    List<ChatMessage> messages,
  ) async {
    final stored = await _readAll(userId);
    final next = [
      for (final entry in stored)
        if (entry.conversation.id != conversation.id) entry,
      _StoredConversation(conversation: conversation, messages: messages),
    ];
    await _writeAll(userId, next);
  }

  /// Updates just the metadata (title/timestamps) for a batch of
  /// [conversations] — e.g. after `GET /api/conversations` — without
  /// touching any messages already cached for those ids. Used so the
  /// drawer's recent-conversations list can still work from cache when
  /// offline, even though only the currently-open conversation's full
  /// message history is normally cached via [saveConversation].
  Future<void> upsertConversationMetadata(
    String userId,
    List<Conversation> conversations,
  ) async {
    final stored = await _readAll(userId);
    final byId = {for (final entry in stored) entry.conversation.id: entry};
    for (final conversation in conversations) {
      final existing = byId[conversation.id];
      byId[conversation.id] = _StoredConversation(
        conversation: conversation,
        messages: existing?.messages ?? const [],
      );
    }
    await _writeAll(userId, byId.values.toList());
  }

  Future<void> deleteConversation(String userId, String conversationId) async {
    final stored = await _readAll(userId);
    final next = [
      for (final entry in stored)
        if (entry.conversation.id != conversationId) entry,
    ];
    await _writeAll(userId, next);
  }
}

class _StoredConversation {
  const _StoredConversation({
    required this.conversation,
    required this.messages,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => {
    'conversation': conversation.toJson(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory _StoredConversation.fromJson(Map<String, dynamic> json) {
    return _StoredConversation(
      conversation: Conversation.fromJson(
        json['conversation'] as Map<String, dynamic>,
      ),
      messages: (json['messages'] as List? ?? const [])
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
