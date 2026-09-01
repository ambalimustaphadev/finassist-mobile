import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/uploaded_statement.dart';

/// On-device record of the user's uploaded statements, keyed per user so
/// switching accounts never shows one user's financial data to another.
/// Same rationale and storage choice as `LocalConversationStore` and
/// `ProfileImageStore`: the backend has no endpoint yet for listing or
/// deleting a user's statements/financial data server-side, so this is the
/// closest thing to a source of truth available today, and it's real data
/// (what this device has actually uploaded), not a placeholder.
class FinancialDataStore {
  FinancialDataStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String userId) => 'financial_data_v1_$userId';

  Future<List<UploadedStatement>> loadStatements(String userId) async {
    final raw = await _storage.read(key: _key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => UploadedStatement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveStatements(
    String userId,
    List<UploadedStatement> statements,
  ) async {
    final raw = jsonEncode(statements.map((s) => s.toJson()).toList());
    await _storage.write(key: _key(userId), value: raw);
  }

  Future<void> addStatement(String userId, UploadedStatement statement) async {
    final existing = await loadStatements(userId);
    await _saveStatements(userId, [statement, ...existing]);
  }

  /// Removes all financial data for [userId] — the account, conversations
  /// and profile picture (stored under separate keys) are left untouched.
  Future<void> clear(String userId) async {
    await _storage.delete(key: _key(userId));
  }
}
