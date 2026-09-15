import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Thrown for any non-2xx response from [ApiClient] that isn't a 401 —
/// carries the backend's own message (parsed from whichever of the two
/// error shapes this backend uses) plus the status code so callers can
/// branch when they need to (e.g. 404).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.details});

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  @override
  String toString() => message;
}

/// Thrown when there's no stored access token, or the backend reports the
/// current one has expired/is invalid — lets callers uniformly prompt for
/// login again, the same vocabulary `ChatUnauthorizedException` already
/// uses for the (untouched) chat repository.
class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException()
    : super('Your session has expired. Please log in again.', statusCode: 401);
}

class ApiNotFoundException extends ApiException {
  const ApiNotFoundException([super.message = 'Not found'])
    : super(statusCode: 404);
}

/// A small shared HTTP helper for the newer, non-chat API surface
/// (profile, preferences, activity, notifications, documents).
/// Deliberately separate from `ApiChatRepository`/
/// `ApiFileUploadRepository`/`ApiAuthRepository`, which each already work
/// and are not touched here — this only exists to avoid re-hand-rolling
/// the same auth-header/timeout/error-parsing boilerplate 6+ more times.
///
/// The backend's error responses come in two shapes depending on which
/// route answered: auth/file routes use flat `{"error": "..."}`; profile/
/// preferences/activity/notifications use structured
/// `{"error": {"code","message","details"?}}`. [_parseError] understands
/// both.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _timeout = Duration(seconds: 12);

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) {
      throw const ApiUnauthorizedException();
    }
    return {
      // Explicit `charset=utf-8`, rather than relying on `package:http`'s
      // own `application/json` special-case default, so encoding a body
      // with non-Latin1 characters (currency symbols like ₦, `→`, accented
      // names) never depends on that fallback rule holding.
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _guarded(() async {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: (query == null || query.isEmpty) ? null : query,
      );
      final headers = await _authHeaders(json: false);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);
      return _decode(response);
    });
  }

  /// Like [get], but for the handful of endpoints (e.g.
  /// `/api/subscriptions`) that respond with a bare JSON array rather than
  /// an object — [get]'s `_decode` would silently discard that to `{}`.
  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) {
    return _guarded(() async {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: (query == null || query.isEmpty) ? null : query,
      );
      final headers = await _authHeaders(json: false);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);
      _throwOnError(response);
      if (response.bodyBytes.isEmpty) return const [];
      final decoded = jsonDecode(_utf8Body(response));
      return decoded is List ? decoded : const [];
    });
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _guarded(() async {
      final headers = await _authHeaders();
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _decode(response);
    });
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _guarded(() async {
      final headers = await _authHeaders();
      final response = await _client
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _decode(response);
    });
  }

  Future<void> delete(String path) {
    return _guarded(() async {
      final headers = await _authHeaders(json: false);
      final response = await _client
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(_timeout);
      _throwOnError(response);
    });
  }

  /// Multipart upload for the profile-picture endpoint — mirrors
  /// `ApiFileUploadRepository`'s multipart pattern (only the Authorization
  /// header, no top-level `Content-Type` — `http` sets the multipart
  /// boundary itself).
  ///
  /// [contentType] is the MIME type of the file *part* (e.g. `image/jpeg`).
  /// `http.MultipartFile.fromPath` doesn't infer this from the path, and
  /// defaults it to `application/octet-stream` when omitted — silently
  /// mislabeling every upload regardless of the file's real type. Callers
  /// that know the real type (having sniffed the file's content) should
  /// pass it through so the backend receives an accurate Content-Type.
  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required String fieldName,
    required File file,
    String? contentType,
  }) {
    return _guarded(() async {
      final headers = await _authHeaders(json: false);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll(headers)
        ..files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            contentType: contentType == null
                ? null
                : MediaType.parse(contentType),
          ),
        );
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    });
  }

  Map<String, dynamic> _decode(http.Response response) {
    _throwOnError(response);
    if (response.bodyBytes.isEmpty) return const {};
    final decoded = jsonDecode(_utf8Body(response));
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  /// Decodes the raw response bytes as UTF-8 directly rather than trusting
  /// `response.body`'s own charset guessing (which only special-cases a
  /// bare `application/json` Content-Type — anything else without an
  /// explicit charset silently falls back to latin1, mangling non-ASCII
  /// content like currency symbols or accented names). JSON is UTF-8 by
  /// spec, so this holds regardless of what the server declares.
  String _utf8Body(http.Response response) => utf8.decode(response.bodyBytes);

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) throw const ApiUnauthorizedException();

    final parsed = _parseError(response);
    if (response.statusCode == 404) {
      throw ApiNotFoundException(parsed.$1 ?? 'Not found');
    }
    throw ApiException(
      parsed.$1 ?? 'Request failed (${response.statusCode}).',
      statusCode: response.statusCode,
      code: parsed.$2,
      details: parsed.$3,
    );
  }

  /// Returns (message, code, details), any of which may be null — handles
  /// both the flat `{"error": "..."}` and structured
  /// `{"error": {"code","message","details"}}` shapes.
  (String?, String?, Map<String, dynamic>?) _parseError(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(_utf8Body(response));
      if (decoded is! Map) return (null, null, null);
      final error = decoded['error'];
      if (error is String) return (error, null, null);
      if (error is Map) {
        return (
          error['message'] as String?,
          error['code'] as String?,
          (error['details'] as Map?)?.cast<String, dynamic>(),
        );
      }
    } catch (_) {
      // Fall through to the generic status-code message.
    }
    return (null, null, null);
  }

  Future<T> _guarded<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        "Couldn't connect. Please check your connection and try again.",
      );
    } catch (error) {
      throw ApiException('Something went wrong: $error');
    }
  }
}
